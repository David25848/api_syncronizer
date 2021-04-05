# Scripts

## Instanciar tienda y ver cantidad de productos en API, Rails y Woo
```ruby
store = Store.find_by(sku: ENV['STORE_SKU'])
api_products = store.api_products
woo_products = store.woo_products
api_products.size
store.products.size
woo_products.size
```

# Ver productos en API que deberían pasar a Rails
```ruby
api_products_may_save = api_products.reject do |x|
  x['images'].blank? ||
  x['clasificadores'].blank? ||
  x['variations'].blank? ||
  x['name'].blank? ||
  x['sku'].blank? ||
  x['slug'].blank? ||
  Product::STATUSES.exclude?(x['status']) ||
  Product::TYPES.exclude?(x['type_product'])
end.uniq { |x| x['sku'] }
```

# Contar productos en API que deberían pasar a Rails
```ruby
api_products_may_save.size
```

# Ver productos que no se guardaron en Rails
```ruby
no_saved_in_rails_products = api_products_may_save.select { |x| store.products.map { |x| x.sku.to_s }.exclude?(x['sku'].to_s) }
no_saved_in_rails_products.size
saved_api_products = no_saved_in_rails_products.select { |product| saved_product(product, store) }
```

## Ver productos duplicados
```ruby
woo_duplicated_products_skus = woo_products.group_by { |x| x['sku'] }.map { |k,v| [k, v.size] }.select { |x| x.last > 1 }.map { |x| x.first }
```

## Eliminar productos duplicados
```ruby
woo_duplicated_products = woo_products.select { |x| woo_duplicated_products_skus.include?(x['sku']) }
woo_duplicated_products.map do |woo_duplicated_product|
  same_slugs = woo_products.select { |x| x['sku'] == woo_duplicated_product['sku'] }.map { |x| x['slug'] }.sort
  puts "same_slugs = #{same_slugs}"
  original_slug = same_slugs.first
  puts "original_slug = #{original_slug}"
  duplicated_slugs = same_slugs - [original_slug]
  puts "duplicated_slugs = #{duplicated_slugs}"
  products_to_delete = woo_duplicated_products.select { |x| duplicated_slugs.include?(x['slug']) }
  puts "products_to_delete = #{products_to_delete}"
  products_to_delete.map do |product|
    response = store.woo_store.delete("products/#{product['id']}", force: true).parsed_response
    if response&.dig('id')
      puts "ELIMINADO #{response['sku']} SLUG=#{response['slug']}"
    else
      puts "IGNORADO #{product['sku']} SLUG=#{product['slug']}"
    end
  end
end
```

## Elimina imágenes con mayúsculas o espacios y eliminar productos sin imágenes correctas
```ruby
store.products.map do |product|
  images = product.images.reject { |x| x['src'].count('A-Z') > 0 || x['src'].count(' ') > 0 }
  if images.blank?
    product.destroy
    puts "#{product.sku} ELIMINADO"
  elsif images != product.images
    product.update!(images: images, store: store)
    puts "#{product.sku} ACTUALIZADO"
  end
end
```

## Ver productos de Rails que no se han creado en Woo
```ruby
no_created_products_skus = store.products.pluck(:sku) - woo_products.map { |x| x['sku'] }
```

## Crear productos en Woo que no se crearon antes
```ruby
no_created_products_skus.map do |sku|
  product = store.products.find_by(sku: sku)
  response = store.woo_store.post('products', product.as_json_with_attributes).parsed_response
  if response&.dig('id')
    puts "CREADO #{sku}"
  else
    puts "NO CREADO #{sku}: #{response['message']}"
  end
end
```

## Ver productos sin variaciones en Woo
```ruby
woo_no_variations_products = woo_products.select { |x| x['variations'].blank? }
woo_no_variations_products_skus = woo_no_variations_products.map { |x| x['sku'] }.sort
variations_products = store.products.where(sku: woo_no_variations_products_skus)
```

## Cargar variaciones para productos sin variaciones en Woo
```ruby
variations_products.map do |product|
  rails_product = Product.find_by(sku: product['sku'])
  next unless rails_product
  puts rails_product ? "ENCONTRADO #{rails_product.build_json_variations}" : 'IGNORADO'

  rails_product&.update(woocommerce_id: product['id'])

  rails_product.build_json_variations&.each do |variation|
    begin
      Rails.logger.info "===> Getting variation #{variation[:sku]} for product #{rails_product.sku}"
      woo_variation = store.woo_store.get("products/#{product['id']}/variations", { sku: variation[:sku] }).parsed_response&.first
    rescue StandardError
      Rails.logger.error "!!! ERROR: Cannot get variation #{variation[:sku]} for product #{product[:sku]}"
    end
    if woo_variation&.dig('id')
      # Rails.logger.info "Updating variation to Woo: #{variation}"
      # Update variation
      begin
        Rails.logger.info "===> Updating variation #{variation[:sku]} for product #{rails_product.sku}"
        updated_variation = store.woo_store.put("products/#{product['id']}/variations/#{woo_variation['id']}", variation).parsed_response
        if updated_variation&.dig('id')
          Rails.logger.info "===> UPDATED variation #{variation[:sku]} for product #{product[:sku]}"
        else
          Rails.logger.info "!!! Error: Failed updating variation #{variation[:sku]} for product #{product[:sku]}: #{created_variation['message']}"
        end
      rescue StandardError
        Rails.logger.error "!!! ERROR: Cannot update variation #{variation[:sku]} for product #{product[:sku]}"
      end
      next
    else
      # Rails.logger.info "Creating variation to Woo: #{variation}"
      # Create variation
      begin
        Rails.logger.info "===> Creating variation #{variation[:sku]} for product #{rails_product.sku}"
        created_variation = store.woo_store.post("products/#{product['id']}/variations", variation).parsed_response
        if created_variation&.dig('id')
          Rails.logger.info "===> CREATED variation #{variation[:sku]} for product #{product[:sku]}"
        else
          Rails.logger.info "!!! Error: Failed creating variation #{variation[:sku]} for product #{product[:sku]}: #{created_variation['message']}"
        end
      rescue StandardError
        Rails.logger.error "!!! ERROR: Cannot create variation #{variation[:sku]} for product #{product[:sku]}"
      end
    end
  end
end
```
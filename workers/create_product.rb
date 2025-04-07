def create_product_async(queue_id, product_name)
  PRODUCTS_QUEUE[queue_id] = {status: 'processing', product_id: nil}
  sleep 5
  product_id = SecureRandom.uuid
  PRODUCTS[product_id] = { id: product_id, nombre: product_name }
  PRODUCTS_QUEUE[queue_id] = {status: 'done', product_id: product_id}
end
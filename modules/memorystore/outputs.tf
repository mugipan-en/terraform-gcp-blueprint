output "redis_instances" {
  description = "Redis instances information"
  value = {
    for k, v in google_redis_instance.redis_instances : k => {
      id                       = v.id
      name                     = v.name
      region                   = v.region
      tier                     = v.tier
      memory_size_gb           = v.memory_size_gb
      redis_version            = v.redis_version
      host                     = v.host
      port                     = v.port
      current_location_id      = v.current_location_id
      create_time              = v.create_time
      state                    = v.state
      status_message           = v.status_message
      auth_string              = v.auth_string
      server_ca_certs          = v.server_ca_certs
      persistence_iam_identity = v.persistence_iam_identity
    }
  }
  sensitive = true
}

output "redis_connection_info" {
  description = "Redis connection information"
  value = {
    for k, v in google_redis_instance.redis_instances : k => {
      host = v.host
      port = v.port
      url  = "redis://${v.host}:${v.port}"
    }
  }
  sensitive = true
}

output "redis_auth_strings" {
  description = "Redis authentication strings"
  value = {
    for k, v in google_redis_instance.redis_instances : k => v.auth_string if v.auth_enabled
  }
  sensitive = true
}

output "memcached_instances" {
  description = "Memcached instances information"
  value = {
    for k, v in google_memcache_instance.memcached_instances : k => {
      id                 = v.id
      name               = v.name
      region             = v.region
      node_count         = v.node_count
      memcache_version   = v.memcache_version
      discovery_endpoint = v.discovery_endpoint
      memcache_nodes     = v.memcache_nodes
      create_time        = v.create_time
      state              = v.state
    }
  }
}

output "memcached_connection_info" {
  description = "Memcached connection information"
  value = {
    for k, v in google_memcache_instance.memcached_instances : k => {
      discovery_endpoint = v.discovery_endpoint
      nodes              = v.memcache_nodes
    }
  }
}

# Connection examples for applications
output "redis_connection_examples" {
  description = "Redis connection examples for different languages"
  value = {
    for k, v in google_redis_instance.redis_instances : k => {
      python = "redis.Redis(host='${v.host}', port=${v.port}, password='${v.auth_string}')"
      nodejs = "const redis = require('redis'); const client = redis.createClient({host: '${v.host}', port: ${v.port}, password: '${v.auth_string}'});"
      go     = "redis.NewClient(&redis.Options{Addr: '${v.host}:${v.port}', Password: '${v.auth_string}'})"
      java   = "Jedis jedis = new Jedis('${v.host}', ${v.port}); jedis.auth('${v.auth_string}');"
    }
  }
  sensitive = true
}

output "memcached_connection_examples" {
  description = "Memcached connection examples for different languages"
  value = {
    for k, v in google_memcache_instance.memcached_instances : k => {
      python = "import memcache; mc = memcache.Client(['${v.discovery_endpoint}'])"
      nodejs = "const memcached = require('memcached'); const mc = new memcached('${v.discovery_endpoint}');"
      go     = "mc := memcache.New('${v.discovery_endpoint}')"
      java   = "MemcachedClient mc = new MemcachedClient(AddrUtil.getAddresses('${v.discovery_endpoint}'));"
    }
  }
}

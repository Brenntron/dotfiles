class RuntimeConfig

  ##config

  RELOAD_CATEGORIES = "RELOAD_CATEGORIES"

  #later on should wrap all of this in connection pool

  def self.redis_store
    Redis.new
  end

  def self.set_category_reload(reload=false)
    redis_store.set(RELOAD_CATEGORIES, reload)
  end

  def self.get_category_reload
    redis_store.get(RELOAD_CATEGORIES)
  end
end
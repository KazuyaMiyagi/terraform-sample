variable "laravel_environments" {
  type = map(string)
  default = {
    "APP_NAME"         = "",
    "APP_ENV"          = "",
    "APP_DEBUG"        = "",
    "APP_LOG_LEVEL"    = "",
    "APP_URL"          = "",
    "DB_CONNECTION"    = "",
    "DB_HOST"          = "",
    "DB_PORT"          = "",
    "DB_DATABASE"      = "",
    "DB_USERNAME"      = "",
    "BROADCAST_DRIVER" = "",
    "CACHE_DRIVER"     = "",
    "SESSION_DRIVER"   = "",
    "QUEUE_DRIVER"     = "",
    "REDIS_HOST"       = "",
    "REDIS_PORT"       = "",
    "MAIL_DRIVER"      = "",
    "MAIL_HOST"        = "",
    "MAIL_PORT"        = "",
    "MAIL_USERNAME"    = "",
    "MAIL_ENCRYPTION"  = "",
    "PUSHER_APP_ID"    = ""
  }
}

variable "laravel_secure_environments" {
  type = map(string)
  default = {
    "APP_KEY"           = "",
    "DB_PASSWORD"       = "",
    "REDIS_PASSWORD"    = "",
    "MAIL_PASSWORD"     = "",
    "PUSHER_APP_KEY"    = "",
    "PUSHER_APP_SECRET" = ""
  }
}

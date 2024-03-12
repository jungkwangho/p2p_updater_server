from django.apps import AppConfig


class CatalogConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'catalog'
    SITE_HEADER = "Nexess Client Updater 관리"
    SITE_TITLE = "Nexess Client Updater 관리"
    INDEX_TITLE = "Nexess Client Updater 관리"
    UPLOAD_BASE = "./files"

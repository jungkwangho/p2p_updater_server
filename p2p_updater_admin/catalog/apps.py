from django.apps import AppConfig


class CatalogConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'catalog'
    SITE_HEADER = "INITECH Updater 관리"
    SITE_TITLE = "INITECH Updater"
    INDEX_TITLE = "INITECH Updater 관리 메인 페이지"
    UPLOAD_BASE = "./files"

from django.contrib import admin
from .models import File, Report
from .apps import CatalogConfig

"""
+-------------+---------------+------+-----+---------+----------------+
| id          | int(11)       | NO   | PRI | NULL    | auto_increment |
| userid      | varchar(256)  | YES  |     | NULL    |                |
| ip          | varchar(256)  | YES  |     | NULL    |                |
| old_hash    | varchar(256)  | NO   |     | NULL    |                |
| new_hash    | varchar(256)  | NO   |     | NULL    |                |
| old_name    | varchar(64)   | NO   |     | NULL    |                |
| new_name    | varchar(64)   | NO   |     | NULL    |                |
| old_version | varchar(32)   | NO   |     | NULL    |                |
| new_version | varchar(32)   | NO   |     | NULL    |                |
| err_code    | int(11)       | NO   |     | NULL    |                |
| err_msg     | varchar(1024) | YES  |     | NULL    |                |
| report_date | datetime(6)   | NO   |     | NULL    |                |
+-------------+---------------+------+-----+---------+----------------+
"""

class FileAdmin(admin.ModelAdmin):
    # columns layout
    list_display = ('id', 'type', 'name', 'hash', 'version', 'stored_path', 'enable', 'register_date', 'last_modified', 'update_id')
    # filter
    list_filter = ('type', 'name', 'enable')

class ReportAdmin(admin.ModelAdmin):
    # columns layout
    list_display = ('userid', 'ip', 'old_name', 'old_version', 'new_name', 'new_version', 'err_code', 'err_msg', 'report_date')
    # filter
    list_filter = ('old_name', 'new_name', 'err_code', 'err_msg')
    # add/edit layout
    fields = ['userid', 'ip', ('old_name', 'old_version', 'old_hash'), ('new_name', 'new_version', 'new_hash'), 'err_code', 'err_msg']

admin.site.site_header = CatalogConfig.SITE_HEADER
admin.site.site_title = CatalogConfig.SITE_TITLE
admin.site.index_title = CatalogConfig.INDEX_TITLE
admin.site.register(File, FileAdmin)
admin.site.register(Report, ReportAdmin)

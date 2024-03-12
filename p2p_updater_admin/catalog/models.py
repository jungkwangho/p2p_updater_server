from django.db import models
from django.db.models import UniqueConstraint
from django.db.models.functions import Lower
from django.db.models.signals import post_delete, pre_save
from django.core.files.storage import FileSystemStorage, default_storage
from django.core.exceptions import ValidationError
from django.utils.deconstruct import deconstructible
from .apps import CatalogConfig

import os
import os.path
import hashlib
from datetime import date

from .utils_os_windows import get_windows_file_version_from_buffer
from .utils import delete_file_cleanup, update_file_cleanup
"""
+---------------+---------------+------+-----+---------+----------------+
| Field         | Type          | Null | Key | Default | Extra          |
+---------------+---------------+------+-----+---------+----------------+
| id            | int(11)       | NO   | PRI | NULL    | auto_increment |
| type          | varchar(1)    | NO   |     | NULL    |                |
| version       | varchar(32)   | NO   |     | NULL    |                |
| hash          | varchar(256)  | NO   | UNI | NULL    |                |
| name          | varchar(64)   | NO   |     | NULL    |                |
| stored_path   | varchar(1024) | YES  |     | NULL    |                |
| update_id     | int(11)       | YES  |     | NULL    |                |
| enable        | tinyint(1)    | NO   |     | NULL    |                |
| register_date | datetime(6)   | NO   |     | NULL    |                |
| last_modified | datetime(6)   | NO   |     | NULL    |                |
+---------------+---------------+------+-----+---------+----------------+
"""

def user_directory_path(instance, filename):

    ctx = hashlib.sha256()
    instance.stored_path.seek(0)
    totalbytes = bytearray()
    if instance.stored_path.multiple_chunks():
        for data in instance.stored_path.chunks(65535):
            ctx.update(data)
            totalbytes += data
    else:
        data = instance.stored_path.read()
        ctx.update(data)
        totalbytes += data

    hashvalue = ctx.hexdigest()

    setattr(instance, 'name', filename)
    setattr(instance, 'hash', hashvalue)

    default_version  = instance.version
    version = get_windows_file_version_from_buffer(totalbytes)
    if version == '':
        version = default_version
    
    setattr(instance, 'version', version)

    return os.path.join(CatalogConfig.UPLOAD_BASE, filename)

# 이게 없으면 makemigration 시 오류가 발생한다.
@deconstructible
class FileValidator(object):
    def __call__(self, data):
        ctx = hashlib.sha256()
        data.seek(0)
        ctx.update(data.read())
        hashvalue = ctx.hexdigest()
        if File.objects.filter(hash__iexact=hashvalue).count() > 0:
            raise ValidationError(f'The file already exists: %s', 'hash', {'hash':hashvalue})

class File(models.Model):

    FILE_TYPES = (
        ('F', '개별 파일'),
        ('P', '설치 패키지'),
    )

    # 반드시 FileField 가 가장 상위에 있어야 한다. 그렇지 않으면 user_directory_path 에서 지정한 hash, name 이 반영안됨

    fvalidator = FileValidator()
    stored_path = models.FileField('파일 업로드', max_length=1024, null=True, blank=True, help_text="파일 경로", upload_to=user_directory_path, validators=[fvalidator])
    id = models.AutoField('파일 ID', primary_key=True, blank=True)
    type = models.CharField("파일 타입", max_length=1, choices=FILE_TYPES, help_text="개별 파일, 설치 패키지 중 택1")
    version = models.CharField('파일 버전', max_length=32, default="1.0", help_text="File Version이 명시된 윈도우 실행파일의 경우 자동으로 해당 버전 적용")
    hash = models.CharField('파일 해쉬', max_length=256, unique=True, blank=True, editable=False, help_text="File sha256 hash in lower case hex string")
    name = models.CharField('파일 이름', max_length=256, editable=False, help_text="File name")
    update_id = models.IntegerField('업데이트 파일 ID', null=True, blank=True, help_text="이 파일의 업데이트(신버전)에 해당하는 파일의 파일ID")
    enable = models.BooleanField('업데이트 사용 여부', default=True, blank=True, help_text="Enable using this file")
    register_date = models.DateTimeField('등록 일시', auto_now_add=True, blank=True, help_text="First registered datetime")
    last_modified = models.DateTimeField('수정 일시', auto_now_add=True, blank=True, help_text="Last modified datetime")
    hashvalue = None

    class Meta:
        ordering = ['name', '-register_date']
        constraints = [
            UniqueConstraint(
                'stored_path',
                name='stored_path_unique',
                violation_error_message = 'file already exists'
            ),
            UniqueConstraint(
                Lower('hash'),
                name='hash_case_insensitive_unique',
                violation_error_message = "hash already exists (case insensitive match)"
            ),
        ]

    def __str__(self):
        return f"{self.name} : {self.version}"

    def get_absolute_url(self):
        return reverse('file-detail-view', args=[str(self.id)])

# File 레코드 삭제시 첨부파일 삭제를 위해
post_delete.connect(
    delete_file_cleanup, sender=File, dispatch_uid="file.stored_path.delete_file_cleanup"
)
pre_save.connect(
    update_file_cleanup, sender=File, dispatch_uid="file.stored_path.update_file_cleanup" 
)


"""    
+-------------+---------------+------+-----+---------+----------------+
| Field       | Type          | Null | Key | Default | Extra          |
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
class Report(models.Model):
    id = models.AutoField('리포트 ID', primary_key=True, blank=True, help_text="Id of a report")
    userid = models.CharField('사용자 아이디', max_length=256, null=True, blank=True, help_text="UserId of who sends this report")
    ip = models.CharField('사용자 IP 주소목록', max_length=256, null=True, blank=True, help_text="a list of IP addresses of who sends this report seperated by ';'")
    old_hash = models.CharField('이전 파일 SHA512 해쉬', max_length=256, help_text="sha512 hash in hexstring of the old file")
    new_hash = models.CharField('신규 파일 SHA512 해쉬', max_length=256, help_text="sha512 hash in hexstring of the new file")
    old_name = models.CharField('이전 파일 이름', max_length=64, help_text="the name of the old file")
    new_name = models.CharField('신규 파일 이름', max_length=64, help_text="the name of the new file")
    old_version = models.CharField('이전 파일 버전', max_length=32, help_text="the version of the old file")
    new_version = models.CharField('신규 파일 버전', max_length=32, help_text="the version of the new file")
    err_code = models.IntegerField('에러 코드', help_text="the error code that occured in updating process")
    err_msg = models.CharField('에러 메시지', max_length=1024, null=True, blank=True, help_text="the description of error code")
    report_date = models.DateTimeField('보고 일시', auto_now_add=True, blank=True, help_text="reported datetime")

    class Meta:
        ordering = ["-report_date"]

    def __str__(self):
        return f"{self.new_name} : {self.new_version}"

    def get_absolute_url(self):
        return reverse('report-detail-view', args=[str(self.id)])


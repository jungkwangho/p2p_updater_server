from django.db import models
from django.db.models import UniqueConstraint
from django.db.models.functions import Upper

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
class File(models.Model):

    FILE_TYPES = (
        ('F', 'Individual file'),
        ('P', 'Installation package'),
    )

    id = models.AutoField('파일 ID', primary_key=True, blank=True, help_text="Id of a file")
    type = models.CharField("파일 타입 (파일'F' 또는 패키지'P' 중 택1)", max_length=1, choices=FILE_TYPES, help_text="Select file type among 'file' or 'package'")
    version = models.CharField('파일 버전', max_length=32, help_text="Enter version of file")
    hash = models.CharField('파일 해쉬', max_length=256, unique=True, help_text="Enter file sha512 hash in upper case hex string")
    name = models.CharField('파일 이름', max_length=64, help_text="Enter file name")
    stored_path = models.CharField('서버 저장 위치', max_length=1024, null=True, blank=True, help_text="Enter stored path of file")
    update_id = models.IntegerField('업데이트 파일 ID', null=True, blank=True, help_text="Id of the update file")
    enable = models.BooleanField('업데이트 사용 여부', default=True, blank=True, help_text="Enable using this file")
    register_date = models.DateTimeField('등록 일시', auto_now_add=True, blank=True, help_text="First registered datetime")
    last_modified = models.DateTimeField('수정 일시', auto_now_add=True, blank=True, help_text="Last modified datetime")

    class Meta:
        ordering = ['name', '-register_date']
        constraints = [
            UniqueConstraint(
                Upper('hash'),
                name='hash_case_insensitive_unique',
                violation_error_message = "hash already exists (case insensitive match)"
            ),
        ]

    def __str__(self):
        return self.hash

    def get_absolute_url(self):
        return reverse('file-detail-view', args=[str(self.id)])

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
    ip = models.CharField('사용자 IP 주소목록(;로 구분)', max_length=256, null=True, blank=True, help_text="a list of IP addresses of who sends this report seperated by ';'")
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
        return f"{self.new_name}_{self.new_version}"

    def get_absolute_url(self):
        return reverse('report-detail-view', args=[str(self.id)])
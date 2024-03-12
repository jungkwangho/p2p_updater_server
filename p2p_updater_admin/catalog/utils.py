import os
from django.core.files.storage import default_storage
from django.db.models import FileField

def update_file_cleanup(sender, instance, *args, **kwargs):
    # 내용이 동일한 파일인 경우에는 validator에 걸려서 이곳에 들어오지 않음
    # 즉 
    # 1. 내용이 다르고 파일명이 같거나 
    # 2. 내용이 다르고 파일명도 다른 경우에 대한 고려만 있으면 된다.
    # 두 경우 모두 기존 파일은 지워야 한다.
    try:
        old_img = instance.__class__.objects.get(id=instance.id).stored_path.path
    except:
        old_img = None
    try:
        new_img = instance.stored_path.path
    except:
        new_img = None
    try:
        if old_img != None and os.path.exists(old_img):
            os.remove(old_img)
        if new_img == None:
            if not str(instance.name).startswith("<deleted>"):
                setattr(instance, 'name', '<deleted>' + instance.name)
            setattr(instance, 'hash', '<none>')
            setattr(instance, 'version', '<none>')
    except Exception as e:
        print(f"An Exception occured in file_cleanup 2: {e}")
        pass

def delete_file_cleanup(sender, instance, *args, **kwargs):
    for field in sender._meta.get_fields():
        if field and isinstance(field, FileField):
            # f 가 FileField
            f = getattr(instance, field.name) 
            m = instance.__class__._default_manager

            has_real_file = False
            try:
                has_real_file = hasattr(f, "path")
            except Exception as e:
                print(f"An Exception occured in file_cleanup 1: {e}")
                pass

            if (
                has_real_file
                and os.path.exists(f.path)
                and not m.filter(
                    **{"%s__exact" % field.name: getattr(instance, field.name)}
                ).exclude(pk=instance._get_pk_val())
            ):
                try:
                    default_storage.delete(f.path)
                except Exception as e:
                    print(f"An Exception occured in file_cleanup 2: {e}")
                    pass
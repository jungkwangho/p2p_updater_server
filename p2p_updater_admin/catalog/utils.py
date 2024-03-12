import os
from django.core.files.storage import default_storage
from django.db.models import FileField

def file_cleanup(sender, **kwargs):
    for field in sender._meta.get_fields():
        """
        try:
            field = sender._meta.get_field(fieldname['name'])
            print("1:", field)
        except Exception as e:
            field = None
            print("2:",  e)
        """

        if field and isinstance(field, FileField):
            inst = kwargs["instance"]
            # f 가 FileField
            f = getattr(inst, field.name) 
            m = inst.__class__._default_manager

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
                    **{"%s__exact" % field.name: getattr(inst, field.name)}
                ).exclude(pk=inst._get_pk_val())
            ):
                try:
                    default_storage.delete(f.path)
                except Exception as e:
                    print(f"An Exception occured in file_cleanup 2: {e}")
                    pass
from django.contrib import admin

# Register your models here.
from .models import BloodRequest, DuplicateDonorAlert, Person


class PersonAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'age', 'gender', 'mobile_number', 'blood_group', 'division', 'district', 'subdistrict', 'lastdonate', 'is_available', 'user', 'created_by')
    list_filter = ('gender', 'blood_group', 'division', 'is_available')
    search_fields = ('name', 'mobile_number', 'district', 'subdistrict')


admin.site.register(Person, PersonAdmin)


@admin.register(DuplicateDonorAlert)
class DuplicateDonorAlertAdmin(admin.ModelAdmin):
    list_display = ('id', 'normalized_phone', 'registered_donor', 'manual_donor', 'status', 'created_at', 'resolved_by')
    list_filter = ('status', 'created_at')
    search_fields = ('normalized_phone', 'registered_donor__name', 'manual_donor__name')
@admin.register(BloodRequest)
class BloodRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'patient_name', 'blood_group', 'hospital', 'district', 'needed_date', 'status')
    list_filter = ('status', 'blood_group', 'division', 'needed_date')
    search_fields = ('patient_name', 'hospital', 'contact_number')

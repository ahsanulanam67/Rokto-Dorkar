from django.contrib import admin

# Register your models here.
from .models import BloodRequest, Person


class PersonAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'age', 'gender', 'mobile_number', 'blood_group', 'division', 'district', 'subdistrict', 'lastdonate', 'is_available', 'longitude', 'latitude')
    list_filter = ('gender', 'blood_group', 'division', 'is_available')
    search_fields = ('name', 'mobile_number', 'district', 'subdistrict')


admin.site.register(Person, PersonAdmin)
@admin.register(BloodRequest)
class BloodRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'patient_name', 'blood_group', 'hospital', 'district', 'needed_date', 'status')
    list_filter = ('status', 'blood_group', 'division', 'needed_date')
    search_fields = ('patient_name', 'hospital', 'contact_number')

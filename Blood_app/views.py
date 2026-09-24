from django.shortcuts import render,redirect
from django.views.decorators.csrf import csrf_exempt
from .models import *
from django.contrib import messages
import json
from django.contrib.auth.models import User
from django.contrib.auth import authenticate,login,logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
import random
from Blood_app.country import country_data
from Accounts.services import OTPDeliveryError
from Blood_app.api.serializers import RegistrationRequestSerializer, RegistrationVerifySerializer

User = get_user_model()

def login_page(request):

    if request.method == "POST":
        email = request.POST.get('email', '').strip().lower()
        password = request.POST.get('password')
        if not User.objects.filter(email__iexact=email).exists():
            messages.info(request,'User not exist')
            return redirect('login_page')
        
        user = authenticate(email=email, password=password)
        # print('Kortamni')
        if user is None:
            messages.info(request,'Invalid Password')
            return redirect('login_page')
        else:
            login(request,user)
            return redirect('main_page')


    return render(request,'login_page.html')

def logout_page(request):

    logout(request)
    return redirect('login_page')
    


def registration_page(request):
    if request.method == "POST":
        serializer = RegistrationRequestSerializer(data=request.POST)
        if serializer.is_valid():
            try:
                serializer.save()
            except OTPDeliveryError as exc:
                messages.error(request, str(exc))
            else:
                context = {'email': serializer.validated_data['email']}
                if getattr(serializer, 'debug_otp', None):
                    messages.info(request, f"Development OTP: {serializer.debug_otp}")
                return render(request, 'verify_otp_page.html', context)
        else:
            for errors in serializer.errors.values():
                for error in errors:
                    messages.error(request, error)
        
    return render(request,'registration_page.html')


def verify_registration_page(request):
    if request.method != 'POST':
        return redirect('registration_page')
    serializer = RegistrationVerifySerializer(data=request.POST)
    if serializer.is_valid():
        user = serializer.validated_data['user']
        login(request, user)
        return redirect('account_page')
    for errors in serializer.errors.values():
        for error in errors:
            messages.error(request, error)
    return render(request, 'verify_otp_page.html', {'email': request.POST.get('email', '')})

@login_required(login_url="/login_page")
def account_page(request):
    
    person,created = Person.objects.get_or_create(user=request.user)
    if request.method =="POST":
        data = request.POST
        person_image = request.FILES.get('person_image')
        name = data.get('name')
        age =  data.get('age')
        gender = data.get('gender')
        mobile_number = data.get('mobile_number')
        blood_group = data.get('blood_group')
        division  =  data.get('division')
        district =  data.get('district')
        subdistrict =  data.get('subdistrict')
        lastdonate =  data.get('lastdonate')
        if person_image:
          person.person_image = person_image
        person.name = name
        person.age = age
        person.gender = gender
        person.mobile_number = mobile_number
        person.blood_group = blood_group
        person.division = division
        person.district = district
        person.subdistrict = subdistrict
        person.lastdonate = lastdonate
        person.save()

        return redirect('account_page')
    
  
    context =  {
         'country': country_data,
         'person': person,
      }
    
    return render(request , 'account_page.html',context)

@login_required(login_url="/login_page")
def main_page(request):
    queryset = Person.objects.all().order_by('-id')[:200]
    
    print(queryset)
    if request.method == "POST":
        data = request.POST
        blood_group = data.get('blood_group')
        division = data.get('division')
        district = data.get('district')
        subdistrict = data.get('subdistrict')
        
        filters = {}
        
        # Apply filters based on provided input
        if blood_group:
            filters['blood_group'] = blood_group
        if division != "ALL":
            filters['division'] = division
        if district != "ALL":
            filters['district'] = district
        if subdistrict != "ALL":
            filters['subdistrict'] = subdistrict
        print(blood_group)
        # Filter people who donated at least 4 months ago
        filters['lastdonate__lte'] = timezone.now().date() - timedelta(days=4*30)
        filtered_ids = Person.objects.filter(**filters).values_list('id', flat=True)
        
        # Shuffle and limit to 200 people
        filtered_ids = random.sample(list(filtered_ids), min(200, len(filtered_ids)))
        queryset = Person.objects.filter(id__in=filtered_ids)

    context = {'person': queryset, 'country': country_data}
    return render(request, 'main_page.html', context)


def about_page(request):
    return render(request, 'about_page.html')

"""
URL configuration for Blood project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
from django.contrib.staticfiles.urls import staticfiles_urlpatterns

# Import views from the Blood_app
from Blood_app.views import account_page, about_page, main_page, login_page, registration_page, verify_registration_page, logout_page

urlpatterns = [
    # Admin URL
    path('admin/', admin.site.urls),
    
    # Application URLs
    path('account_page/', account_page, name='account_page'),
    path('main_page/', main_page, name='main_page'),
    path('login_page/',login_page,name="login_page"),
    path('logout_page/',logout_page,name="logout_page"),
    path('registration_page/',registration_page,name="registration_page"),
    path('verify_registration/', verify_registration_page, name='verify_registration'),
    path('about_page/', about_page, name='about_page'),
    path('api/v1/', include('Blood_app.api.urls')),
    # path('about_page/',about_page,name='about_page')
    
]

# Serving media files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Serving static files
urlpatterns += staticfiles_urlpatterns()

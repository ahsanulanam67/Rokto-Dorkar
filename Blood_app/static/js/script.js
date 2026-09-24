
function togglePopup() {
    
    var popup = document.getElementById("popup");
    if(popup.style.display =="block"){
        
        popup.style.display = "none";
    }
    else {

        popup.style.display = "block";
    }
}
function home_page(){

    window.location.href = 'http://192.168.1.116:8000/main_page/';

}

const country = JSON.parse(document.getElementById('country').textContent);

function updateDivision(){

      const divisionSelect = document.getElementById("division");

      divisionSelect.innerHTML = "";
      for (division in country) {
            
        const option = document.createElement("option");
        option.value = division;
        option.text = division;
        divisionSelect.appendChild(option);
    }
    divisionSelect.addEventListener("change",function(){updateDistricts()});
    updateDistricts();
    
}

function updateDistricts() {
   
    const divisionSelect = document.getElementById("division");
    const districtSelect = document.getElementById("district");
    
    const selectedDivision = divisionSelect.value;
    districtSelect.innerHTML = "";

    if (country[selectedDivision]) {
        
        for (district in country[selectedDivision]) {
            
            const option = document.createElement("option");
            option.value = district;
            option.text = district;
            districtSelect.appendChild(option);
        }
      
    }
    districtSelect.addEventListener("change", updateSubDistricts);
    updateSubDistricts()
}


function updateSubDistricts() {

    const divisionSelect = document.getElementById("division");
    const districtSelect = document.getElementById("district");
    const subdistrictSelect = document.getElementById("subdistrict");

    const selectedDivision = divisionSelect.value;
    const selectedDistrict = districtSelect.value;

    subdistrictSelect.innerHTML = "";
    
    if (country[selectedDivision] && country[selectedDivision][selectedDistrict]) {

        // console.log(country[selectedDivision][selectedDistrict]);
        
        for (ind in country[selectedDivision][selectedDistrict]) {
            
            const option = document.createElement("option");
            option.value = country[selectedDivision][selectedDistrict][ind];
            option.text = country[selectedDivision][selectedDistrict][ind];
            subdistrictSelect.appendChild(option);
        }
      
    }
    
}

document.addEventListener("DOMContentLoaded", function() {
    updateDivision();
});

function updateAccountDivision(){
   
    const divisionSelect = document.getElementById("account_division");

    divisionSelect.innerHTML = "";
    for (division in country) {
      const option = document.createElement("option");
      option.value = division;
      option.text = division;
      divisionSelect.appendChild(option);
  }
  divisionSelect.addEventListener("change",function(){updateAccountDistricts()});
  updateAccountDistricts();
  
  
}

function updateAccountDistricts() {
   
    const divisionSelect = document.getElementById("account_division");
    const districtSelect = document.getElementById("account_district");
    
    const selectedDivision = divisionSelect.value;
    districtSelect.innerHTML = "";

    if (country[selectedDivision]) {
        
        for (district in country[selectedDivision]) {
            
            const option = document.createElement("option");
            option.value = district;
            option.text = district;
            districtSelect.appendChild(option);
        }
      
    }
    districtSelect.addEventListener("change", updateAccountSubDistricts);
    
    updateAccountSubDistricts();
}

function updateAccountSubDistricts() {

    const divisionSelect = document.getElementById("account_division");
    const districtSelect = document.getElementById("account_district");
    const subdistrictSelect = document.getElementById("account_subdistrict");

    const selectedDivision = divisionSelect.value;
    const selectedDistrict = districtSelect.value;

    subdistrictSelect.innerHTML = "";
    
    if (country[selectedDivision] && country[selectedDivision][selectedDistrict]) {

        // console.log(country[selectedDivision][selectedDistrict]);
        
        for (ind in country[selectedDivision][selectedDistrict]) {
            
            const option = document.createElement("option");
            option.value = country[selectedDivision][selectedDistrict][ind];
            option.text = country[selectedDivision][selectedDistrict][ind];
            subdistrictSelect.appendChild(option);
        }
      
    }
    
}

document.addEventListener("DOMContentLoaded", function() {
    updateAccountDivision();
});

function account_form() {
    
    var popup = document.getElementsByClassName("account_form")[0];
    var account_info = document.getElementsByClassName("account_info")[0];

    if(popup.style.display =="block"){
        
        account_info.style.display = "block";
        popup.style.display = "none";
    }
    else {
        account_info.style.display = "none";
        popup.style.display = "block";
    }
}
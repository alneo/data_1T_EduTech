// you can use app's unique identifier here
const LOCAL_STORAGE_KEY = "toggle-bootstrap-theme";

const LOCAL_META_DATA = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY));

// you can change this url as needed
const DARK_THEME_PATH = "/tpl/css/bootstrap_dark.min.css";
const DARK_STYLE_LINK = document.getElementById("dark-theme-style");
const THEME_TOGGLER = document.getElementById("theme-toggler");
let isDark = LOCAL_META_DATA && LOCAL_META_DATA.isDark;
if (isDark) { enableDarkTheme(); } else { disableDarkTheme(); }
function toggleTheme() {
    isDark = !isDark;
    if (isDark) {
        enableDarkTheme();
    } else {
        disableDarkTheme();
    }
    const META = { isDark };
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(META));
    return false;
}
function enableDarkTheme() {
    DARK_STYLE_LINK.setAttribute("href", DARK_THEME_PATH);
    $("#theme-toggler").html("🌙");
}
function disableDarkTheme() {
    DARK_STYLE_LINK.setAttribute("href", "");
    $("#theme-toggler").html("🌞");
}

$(document).ready(function(){
    var forms = document.querySelectorAll('.needs-validation');
    Array.prototype.slice.call(forms)
        .forEach(function (form) {
            form.addEventListener('submit', function (event) {
                if (!form.checkValidity()) {
                    event.preventDefault()
                    event.stopPropagation()
                }
                var errorElements = document.querySelectorAll(":invalid");
                $('html, body').animate({
                    scrollTop: $(errorElements[0]).offset().top-100
                }, 200);
                form.classList.add('was-validated')
            }, false);
        })
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl)
    });
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl)
    })
    var toastTrigger = document.getElementById('liveToastBtn')
    var toastLiveExample = document.getElementById('liveToast')
    if (toastTrigger) {
        toastTrigger.addEventListener('click', function () {
            var toast = new bootstrap.Toast(toastLiveExample)
            toast.show()
        })
    }

    $('.dt_range .input-daterange').datepicker({
        format: "dd.mm.yyyy",
        multidateSeparator: "-",
        calendarWeeks: true
    });
});
function ToastShow1(title,body,err,time=0){
    var toastLiveExample = document.getElementById('Toast');
    var toast = new bootstrap.Toast(toastLiveExample);
    $("#Toast_title").html(title);
    let color='#007aff';
    if(err=="1") color='#e91e63';
    if(err=="0") color='#4caf50';
    $("#Toast_img").attr("fill",color);

    if(time==0){
        let now = new Date;
        $("#Toast_time").html(now.getHours()+":"+now.getMinutes());
    }else {
        $("#Toast_time").html(time);
    }
    $("#Toast_body").html(body);
    toast.show();
};
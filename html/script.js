window.addEventListener("message", function(event){

/* =========================
   NOTIFY SYSTEM
========================= */
    let queue = []
    let isShowing = false
    if(event.data.type === "show"){
        queue.push(event.data)
        processQueue()
    }
    function processQueue(){
    if(isShowing || queue.length === 0) return
    isShowing = true
    const data = queue.shift()
    const duration = data.duration || 4000
    const container = document.getElementById("notify-container")
    const notify = document.createElement("div")
    notify.classList.add("notify")
    notify.innerHTML = `
        <div class="row">
            <img src="taxi.png" class="logo">
            <div class="text">${data.text}</div>
        </div>
        <div class="progress">
            <div class="progressbar"></div>
        </div>
    `
    container.appendChild(notify)
    const bar = notify.querySelector(".progressbar")
    setTimeout(()=>{
        notify.classList.add("show")
    },50)
    /* Progressbar */
    bar.style.width = "100%"
    bar.style.transition = "none"
    setTimeout(()=>{
        bar.style.transition = `width ${duration}ms linear`
        bar.style.width = "0%"
    },50)
    /* Remove */
    setTimeout(()=>{
        notify.style.opacity = "0"
        setTimeout(()=>{
            notify.remove()
            isShowing = false
            processQueue() // Start the next notification
        },300)
    }, duration)
}
/*HIDE QB NOTIFICATIONS*/
if(event.data.action === "hideQB"){
        const qb = document.querySelector(".notify-container")
        if(qb){
            qb.style.display = "none"
        }
    }
/* =========================
   TAXIMETER
========================= */
    if(event.data.action === "meterState"){
        const lamp = document.getElementById("taxi-status")
    if(event.data.state === true){
        lamp.style.background = "rgb(4, 167, 4)"
        lamp.style.boxShadow = "0 0 5px #00ff00"
    }else{
        lamp.style.background = "#ff0000"
        lamp.style.boxShadow = "0 0 5px #ff0000"
    }    
    }
    if(event.data.action === "showMeter"){
    document.getElementById("taximeter").style.display = "block"
    }
    if(event.data.action === "startTimer"){
    startTimer()
    }
    if(event.data.action === "stopTimer"){
    stopTimer()
    }
    if(event.data.action === "hideMeter"){
        document.getElementById("taximeter").style.display = "none"
        stopTimer()
    }
    if(event.data.action === "resetMeter"){
    currentFare = 0
    document.getElementById("fare").innerHTML = "$0.00"
    document.getElementById("distance").innerHTML = "0.00 km"
    document.getElementById("time").innerHTML = "00:00"
}
    if(event.data.action === "updateMeter"){
        animateFare(event.data.fare)
        document.getElementById("distance").innerHTML =
        event.data.distance.toFixed(2) + " km"
    }
    if(event.data.action === "rideFinished"){
        todayMoney += event.data.amount
        rides++
        document.getElementById("today").innerHTML = "$" + todayMoney
        document.getElementById("rides").innerHTML = rides
    }
    if(event.data.action === "updateRating"){
    let ratingEl = document.getElementById("rating")
    ratingEl.innerHTML = String(Math.floor(Number(event.data.rating) || 0))
    // Color
    if(event.data.rating >= 50){
        ratingEl.style.color = "#00ff9d"
    } else if(event.data.rating >= 0){
        ratingEl.style.color = "#ffff00"
    } else {
        ratingEl.style.color = "#ff0000"
    }
    }
/* =========================
   HTML TRANSLATE
========================= */
if(event.data.action === "setLocale"){
    document.querySelector(".taxi-title").innerText = event.data.taxiTitle
    document.querySelectorAll(".label")[0].innerText = event.data.fare
    document.querySelectorAll(".label")[1].innerText = event.data.today
    document.querySelectorAll(".label")[2].innerText = event.data.rides
    document.querySelectorAll(".label")[3].innerText = event.data.distance
    document.querySelectorAll(".label")[4].innerText = event.data.time
    document.querySelectorAll(".label")[5].innerText = event.data.ratingLabel
}
})
/* =========================
   TAXAMETER FUNCTIONS
========================= */
    let currentFare = 0
    let startTime = 0
    let timerInterval = null
    let todayMoney = 0
    let rides = 0
function animateFare(newFare){
    let increment = (newFare - currentFare) / 10
    let interval = setInterval(function(){
        currentFare += increment
        if(currentFare >= newFare){
            currentFare = newFare
            clearInterval(interval)
        }
        document.getElementById("fare").innerHTML =
        "$" + currentFare.toFixed(2)
    }, 50)
}
function startTimer(){
    // ❗ Timer is already running → do nothing
    if(timerInterval !== null) return
    startTime = Date.now()
    timerInterval = setInterval(function(){
        let elapsed = Math.floor((Date.now() - startTime) / 1000)
        let minutes = Math.floor(elapsed / 60)
        let seconds = elapsed % 60
        document.getElementById("time").innerHTML =
        minutes.toString().padStart(2,"0") + ":" +
        seconds.toString().padStart(2,"0")
    }, 1000)
}
function stopTimer(){
    clearInterval(timerInterval)
    timerInterval = null
}

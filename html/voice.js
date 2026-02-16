window.addEventListener("message", function (event) {
    if (event.data.action === "play") {
        const audio = new Audio(`sounds/${event.data.sound}.ogg`);
        audio.volume = 1.0;
        audio.play().catch(() => {});
    }
});

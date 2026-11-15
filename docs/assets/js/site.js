/* ==========================================================================
   Complex Functions Explorer — Site Interactions
   - OS detection for primary download CTA & download cards
   - Scroll-spy for Documentation sidebar TOC
   - Mobile navigation toggle
   ========================================================================== */

(function () {
    "use strict";

    const RELEASES = {
        windows: {
            label: "Download for Windows",
            url: "https://github.com/allanino/complex-functions-explorer/releases/latest/download/ComplexFunctionsExplorer.zip"
        },
        linux: {
            label: "Download for Linux",
            url: "https://github.com/allanino/complex-functions-explorer/releases/latest/download/Complex_Functions_Explorer-x86_64.AppImage"
        }
    };

    function detectOS() {
        const ua = (navigator.userAgent || "").toLowerCase();
        const platform = (navigator.platform || "").toLowerCase();
        if (ua.includes("win") || platform.includes("win")) {
            return "windows";
        }
        if (ua.includes("linux") || platform.includes("linux") || ua.includes("x11")) {
            return "linux";
        }
        return null;
    }

    function initOSDownload() {
        const os = detectOS();
        if (!os || !RELEASES[os]) {
            return;
        }

        const heroBtn = document.querySelector("[data-os-download]");
        const heroLabel = document.querySelector("[data-os-download-label]");
        if (heroBtn && heroLabel) {
            heroBtn.setAttribute("href", RELEASES[os].url);
            heroLabel.textContent = RELEASES[os].label;
        }

        const card = document.querySelector(`.download-card[data-os="${os}"]`);
        if (card) {
            card.classList.add("is-recommended");
        }
    }

    function initMobileNav() {
        const toggle = document.querySelector("[data-nav-toggle]");
        const nav = document.querySelector("[data-site-nav]");
        if (!toggle || !nav) {
            return;
        }

        toggle.addEventListener("click", function () {
            const expanded = toggle.getAttribute("aria-expanded") === "true";
            toggle.setAttribute("aria-expanded", String(!expanded));
            nav.classList.toggle("is-open", !expanded);
        });
    }

    function initScrollSpy() {
        const tocLinks = Array.from(document.querySelectorAll(".doc-sidebar .toc-list a[href^='#']"));
        if (!tocLinks.length || !("IntersectionObserver" in window)) {
            return;
        }

        const targets = tocLinks
            .map(function (link) {
                const id = link.getAttribute("href").slice(1);
                return document.getElementById(id);
            })
            .filter(Boolean);

        if (!targets.length) {
            return;
        }

        function setActive(id) {
            tocLinks.forEach(function (link) {
                const match = link.getAttribute("href") === "#" + id;
                link.classList.toggle("is-active", match);
            });
        }

        const observer = new IntersectionObserver(
            function (entries) {
                entries.forEach(function (entry) {
                    if (entry.isIntersecting) {
                        setActive(entry.target.id);
                    }
                });
            },
            {
                rootMargin: "-95px 0px -68% 0px",
                threshold: 0
            }
        );

        targets.forEach(function (section) {
            observer.observe(section);
        });
    }

    document.addEventListener("DOMContentLoaded", function () {
        initOSDownload();
        initMobileNav();
        initScrollSpy();
    });
})();


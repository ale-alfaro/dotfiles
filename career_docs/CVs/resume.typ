#import "lib.typ": *

// #let accent-color = rgb("#83a598")
#let accent-color = rgb("#076678")
#show: resume.with(
    author: (
        firstname: "Alejandro",
        lastname: "Alfaro",
        email: "ale16aflaro@gmail.com",
        github: "ale-alfaro",
        phone: "(650) 483-6627",
        linkedin: "ale-alfaro-867801134",
        address: "Bay Area",
        positions: (
            "Senior Firmware Engineer",
        ),
    ),
    keywords: ("Embedded", "Firmware", "Engineer"),
    description: "Ale Alfaro Resume",
    date: datetime.today().display(),
    language: "en",
    colored-headers: false,
    accent-color: accent-color,
    show-footer: false,
    use-smallcaps: true,
    font: "Fira Sans",
    show-address-icon: false,
    paper-size: "a4",
    profile-picture: none,
)

= Skills & Education


// An alternative way of list out your resume skills
#resume-skill-grid(
    categories-with-values: (
        "Firmware Experiences": (
            strong("Zephyr RTOS Architecture"),
            strong("Bootloader Design"),
            strong("Wireless Medical Wearables Development"),
        ),
        "Tech Proficiencies": (
            strong("Modern C Design Patterns"),
            strong("IPC & Concurrency"),
            "Build/Test Pipelines",
        ),
        "Domain Knowledge": (
            strong("IEC 62304"),
            strong("CE Mark/FDA 510(k)"),
        ),
        "Higher Education": (
            strong("Bachelors and Masters in Mechanical Engineering"),
            "Northwestern Class of 2020",
        ),
    ),
)

// #block(below: 0.65em)
= Relevant Experience

#resume-entry(
    title: "Senior Firmware Engineer",
    location: "Remote",
    date: "January 2025 – Present",
    description: "Sibel Health",
)

#resume-item([
    - Led development of two wearable medical devices — an ICU-grade multi-lead
        ECG sensor for hospital use and an acousto-mechanical sensor for
        therapeutics and clinical research — securing over \$10M in grant
        funding.
    - Architected embedded systems for both products from component selection
        and EVT prototype procurement through early technical de-risking of
        hardware and firmware designs.
    - Initiated and owned transition to firmware services/modules-oriented
        design using ZBus, Zephyr's pub-sub channel based IPC framework,
        positively impacting all our products by enabling re-use of code up to
        50% in some cases and reducing overall development time/cost.
    - Designed a 3-image bootloader strategy (bootloader + app + firmware
        loader) that doubled available ROM from 400KB to 800KB on
        memory-constrained platforms, added OTA recovery mode, and isolated BLE
        image downloads from the application for improved security.
    - Driving huge refactor of a legacy fragile platform built by offshore
        consultants with only on developer (me) and AI agents following IEC
        62304 practices and using latest tools/harnesses.
    - Managing small team unit test initiative to increase our test coverage in
        our SDK from 0 to 30% in our most mission critical software with a focus
        on testing failure paths using simulation platforms such as Renode's
        emulation and Native Sim technologies
])
#set block(below: 0.7em)
#justified-header("Firmware Engineer", "June 2020 - March 2022")
#let link_max = link(
    "https://www.analog.com/en/resources/reference-designs/maxrefdes282.html#rd-overview",
    "MAXREFDES282",
)
#resume-item[
    - #text(
            "Led firmware development for the Maxim Integrated Health Patch Platform ",
        ) #link_max #text(
            ", a reference design showcasing the MAX816178 PPG, ECG, and BIOZ all-in-one AFE",
        )
    - Built a fleet management system to verify quality of medical sensors
        manufactured abroad, reducing defective shipments by 21%. Developed
        diagnostic firmware routines for PCB integrity validation and life-cycle
        stress testing
    - Implemented low-level drivers for sensing components (digital mics,
        multi-lead ECG AFE) and critical peripherals (NAND flash,
        wireless-charging PMICs).
    .
]
#resume-entry(
    title: "Technical Project Manager",
    location: "Chicago, IL and Remote",
    date: "September 2023 – January 2025",
    description: "Sibel Health",
)
#resume-item[
    - Managed the Design History File (DHF) for two next-gen platforms through
        Phase 1–3 of a Medical Device PDP, collaborating with multi-disciplinary
        teams to finalize design inputs before production.
    - Reduced engineering costs by \~\$1–2M by outsourcing hardware and firmware
        development to an offshore partner with strong silicon vendor
        relationships, accelerating component procurement.
    - Coordinated between the offshore team and Sibel leadership through design
        reviews and regular syncs, ensuring Sibel retained ownership of key
        technical decisions while meeting design requirements.
]
#resume-entry(
    title: "Audio & Haptics Software Engineer",
    location: "Cupertino, CA",
    date: "March 2022 – September 2023",
    description: "Apple",
)

#resume-item[
    - Optimized Apple's CoreHaptics framework, achieving 20% less CPU usage
        across haptic and audio playback scenarios.
    - Fixed a fundamental sound wave interpolation bug in Apple's haptic
        synthesizer, eliminating Taptic Engine motion glitches during sustained
        haptic playback.
    - Improved iOS 16 haptic keyboard quality by validating behavior across all
        audio routes (wireless/wired headphones, CarPlay, AirPlay, HDMI) and
        expanded CI/CD test coverage for the CoreHaptics framework.
]


= Interests

Outdoors, The Sopranos, Foraging, and electronic music production

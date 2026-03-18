#import "modern-cv/lib.typ": *

#let accent-color = rgb("#7e9cd8")
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
      "Software Engineer",
    ),
  ),
  keywords: ("Embedded", "Firmware", "Engineer"),
  description: "Ale Alfaro Resume",
  date: datetime.today().display(),
  language: "en",
  colored-headers: false,
  accent-color: accent-color,
  show-footer: false,
  use-smallcaps: false,
  font: ("Fira Sans", "FiraCode Nerd Font"),
  show-address-icon: false,
  paper-size: "us-letter",
  profile-picture: none,
)

= Skills


// An alternative way of list out your resume skills
#resume-skill-grid(
  categories-with-values: (
    "Embedded & Systems": (
      strong("Zephyr RTOS"),
      strong("BLE and IoT Wireless Technology"),
      "Sensor Driver Development",
      "Power Management Electronics",
      "Simulation Technologies for Testing",
      "Tracing/Debugging",
    ),
    "Systems Programming and Scripting": (
      strong("C++"),
      strong("Python"),
      "Bash",
      "Go",
    ),
    "Mobile Development": (
      strong("Swift"),
      "Objective-C",
      "Kotlin",
    ),
    "Medical Device Domain Knowledge": (
      strong("IEC 62304 Development"),
      "Class II Devices",
      "CE Mark and FDA Submissions",
      "IEC 60601",
    ),
  ),
)
// #block(below: 0.65em)
= Experience

#resume-entry(
  title: "Firmware and Hardware Platform Manager",
  location: "Chicago, IL and Remote",
  date: "September 2023 – Present",
  description: "Sibel Health",
)

#resume-item[
  - Led development of two wearable medical devices — an ICU-grade multi-lead ECG sensor for hospital use and an acousto-mechanical sensor for therapeutics and clinical research — securing over \$10M in grant funding.
  - Architected embedded systems for both products from component selection and EVT prototype procurement through early technical de-risking of hardware and firmware designs.
  - Implemented low-level drivers for sensing components (digital mics, multi-lead ECG AFE) and critical peripherals (NAND flash, wireless-charging PMICs).
  - Designed IPC and thread management on Zephyr RTOS across ARM Cortex-M SoCs spanning single-core (nRF52840), dual-core (nRF5340), and quad-core (nRF54H20) architectures.
  - Drove unit test initiative using Native Posix simulation and Antmicro's Renode emulation, growing codebase coverage from 0% to 30% within one month.
  - Designed a 3-image bootloader strategy (bootloader + app + firmware loader) that doubled available ROM from 400KB to 800KB on memory-constrained platforms, added OTA recovery mode, and isolated BLE image downloads from the application for improved security.
]
#resume-entry(
  title: "Technical Project Manager",
  location: "Chicago, IL and Remote",
  date: "September 2023 – Present",
  description: "Sibel Health",
)
#resume-item[
  - Managed the Design History File (DHF) for two next-gen platforms through Phase 1–3 of a Medical Device PDP, collaborating with multi-disciplinary teams to finalize design inputs before production.
  - Reduced engineering costs by \~\$1–2M by outsourcing hardware and firmware development to an offshore partner with strong silicon vendor relationships, accelerating component procurement.
  - Coordinated between the offshore team and Sibel leadership through design reviews and regular syncs, ensuring Sibel retained ownership of key technical decisions while meeting design requirements.
]
#resume-entry(
  title: "Audio & Haptics Software Engineer",
  location: "Cupertino, CA",
  date: "March 2022 – September 2023",
  description: "Apple",
)

#resume-item[
  - Optimized Apple's CoreHaptics framework, achieving 20% less CPU usage across haptic and audio playback scenarios.
  - Fixed a fundamental sound wave interpolation bug in Apple's haptic synthesizer, eliminating Taptic Engine motion glitches during sustained haptic playback.
  - Improved iOS 16 haptic keyboard quality by validating behavior across all audio routes (wireless/wired headphones, CarPlay, AirPlay, HDMI) and expanded CI/CD test coverage for the CoreHaptics framework.
]

#resume-entry(
  title: "Firmware Engineer",
  location: "Niles, IL ",
  date: "June 2020 – March 2022",
  description: "Prior Experience at Sibel Health",
)

#let link_max = link(
  "https://www.analog.com/en/resources/reference-designs/maxrefdes282.html#rd-overview",
  "MAXREFDES282",
)
#resume-item[
  - #text(
      "Led firmware development for the Maxim Integrated Health Patch Platform ",
    )  #link_max #text(
      ", a reference design showcasing the MAX816178 PPG, ECG, and BIOZ all-in-one AFE",
    )
  - Built a fleet management system to verify quality of medical sensors manufactured abroad, reducing defective shipments by 21%. Developed diagnostic firmware routines for PCB integrity validation and life-cycle stress testing.
]
= Education

#resume-entry(
  title: "Northwestern University",
  location: "Evanston, IL",
  date: "Aug 2015 – Dec 2020",
  description: "Bachelor's and Master's in Mechanical Engineering",
)

#resume-item[
  - Relevant Coursework: Mechatronics, Data Structures & Algorithms, Feedback Control Systems, Embedded Systems in Robotics, SLAM
]

= Interests

Surfing, The Sopranos, long distance running, and electronic music production

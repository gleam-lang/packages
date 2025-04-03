import lustre/attribute.{attribute, class}
import lustre/element.{type Element}
import lustre/element/svg

pub fn packages() -> Element(Nil) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 47 51"),
    ],
    [
      svg.g([attribute("clip-path", "url(#clip0_8_219)")], [
        svg.path([
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute("stroke-width", "2"),
          attribute("stroke", "#151515"),
          attribute(
            "d",
            "M7.83333 22.5779L29.7275 34.8709C30.2131 35.1497 30.7634 35.2964 31.3235 35.2964C31.8836 35.2964 32.4339 35.1497 32.9196 34.8709L41.125 30.254C41.7075 29.9249 42.1921 29.4472 42.5293 28.8698C42.8665 28.2923 43.0441 27.6358 43.0441 26.9673C43.0441 26.2988 42.8665 25.6423 42.5293 25.0648C42.1921 24.4874 41.7075 24.0158 41.125 23.6868L39.1384 22.5681M39.1384 22.5681L23.5 13.7619L5.87498 23.6806C5.29247 24.0097 4.80786 24.4874 4.47067 25.0648C4.13348 25.6423 3.95581 26.2988 3.95581 26.9673C3.95581 27.6358 4.13348 28.2923 4.47067 28.8698C4.80786 29.4472 5.29247 29.9249 5.87498 30.254L14.0608 34.871C14.55 35.1497 15.1035 35.2963 15.6666 35.2963C16.2298 35.2963 16.7833 35.1497 17.2725 34.871L39.1384 22.5681Z",
          ),
        ]),
        svg.mask(
          [
            attribute("height", "35"),
            attribute("width", "39"),
            attribute("y", "-3"),
            attribute("x", "6"),
            attribute("maskUnits", "userSpaceOnUse"),
            attribute("style", "mask-type:alpha"),
            attribute.id("mask0_8_219"),
          ],
          [
            svg.path([
              attribute("fill", "#D9D9D9"),
              attribute(
                "d",
                "M24.3104 31.1667L6.88794 20.6429V4.04764L18.6379 -2.83331L44.569 0.404782L42.9483 19.8334L24.3104 31.1667Z",
              ),
            ]),
          ],
        ),
        svg.g([attribute("mask", "url(#mask0_8_219)")], [
          svg.path([
            attribute("fill", "#FFAFF3"),
            attribute(
              "d",
              "M20.2591 3.09182C20.7456 1.68555 22.5545 1.36025 23.4833 2.51196L28.3515 8.54852C28.9539 9.29546 29.8453 9.73806 30.7936 9.76161L38.4616 9.9519C39.9256 9.98821 40.7853 11.6392 39.9976 12.8942L35.8646 19.4786C35.6119 19.8811 35.4471 20.3344 35.3818 20.8078C35.3164 21.2809 35.3519 21.7631 35.4858 22.221L37.6744 29.7093C38.0915 31.136 36.8176 32.4834 35.3997 32.1076L27.977 30.1406C27.5233 30.0203 27.0495 30.001 26.5878 30.0841C26.1264 30.1669 25.6875 30.3503 25.3016 30.6217L18.9863 35.0594C17.7799 35.907 16.131 35.0854 16.0443 33.5992L15.59 25.799C15.5338 24.8336 15.0681 23.9414 14.3144 23.3543L8.22244 18.6086C7.06132 17.7041 7.31567 15.8527 8.67913 15.3079L15.821 12.4542C16.7041 12.1014 17.3933 11.3745 17.7088 10.4625L20.2591 3.09182Z",
            ),
          ]),
          svg.path([
            attribute("fill", "#151515"),
            attribute(
              "d",
              "M21.5909 1.16971C20.7258 1.32532 19.935 1.91116 19.6076 2.85732L17.057 10.2279C16.8083 10.9465 16.2659 11.5186 15.5697 11.7968L8.42756 14.6507C6.59486 15.383 6.24046 17.9539 7.80283 19.171L13.8948 23.9161C14.1881 24.1444 14.4297 24.4345 14.603 24.7668C14.7764 25.099 14.8774 25.4654 14.8992 25.8411L15.3533 33.641C15.4697 35.6421 17.7583 36.7805 19.3801 35.6413L25.6959 31.2034C25.9999 30.9896 26.3457 30.8449 26.7093 30.7795C27.0731 30.7141 27.4464 30.7293 27.8038 30.8242L35.2266 32.7908C37.1325 33.296 38.9014 31.4278 38.3398 29.5065L36.1513 22.0186C36.0458 21.658 36.0179 21.2784 36.0694 20.9056C36.1208 20.533 36.2506 20.1761 36.4498 19.8593L40.5832 13.2746C41.6433 11.5859 40.4482 9.29371 38.4805 9.24489L30.8121 9.05491C30.0646 9.03639 29.363 8.68799 28.8885 8.09953L24.0204 2.06316C23.3955 1.28833 22.4562 1.01409 21.5909 1.16971ZM21.8236 2.51649C22.2167 2.44577 22.6461 2.58429 22.95 2.96112L27.8181 8.99733C28.5481 9.90266 29.6296 10.4394 30.7783 10.4679L38.4467 10.6579C39.4069 10.6817 39.9314 11.6913 39.4157 12.5126L35.2826 19.0971C34.6626 20.0843 34.4949 21.2991 34.823 22.4223L37.0116 29.9102C37.2841 30.8428 36.5049 31.6691 35.575 31.4228L28.1521 29.456C27.0398 29.1611 25.8556 29.3742 24.9092 30.0394L18.5936 34.4771C17.8022 35.0331 16.793 34.5283 16.7364 33.5571L16.2824 25.7572C16.2143 24.587 15.6491 23.5043 14.7357 22.7926L8.64376 18.0475C7.88392 17.4556 8.03841 16.3239 8.93269 15.9665L16.0748 13.1126C17.1448 12.685 17.981 11.8034 18.3636 10.6979L20.9142 3.32729C21.0734 2.86719 21.4304 2.5872 21.8236 2.51649Z",
            ),
          ]),
          svg.path([
            attribute("fill", "#151515"),
            attribute(
              "d",
              "M19.3687 21.0233C20.1091 20.8901 20.6034 20.1701 20.4729 19.4152C20.3424 18.66 19.6364 18.156 18.8961 18.2891C18.1558 18.4223 17.6614 19.1424 17.7919 19.8973C17.9225 20.6523 18.6284 21.1565 19.3687 21.0233Z",
            ),
          ]),
          svg.path([
            attribute("fill", "#151515"),
            attribute(
              "d",
              "M30.3356 19.051C31.0758 18.918 31.5702 18.1979 31.4396 17.4429C31.3091 16.6879 30.6032 16.1838 29.8628 16.3169C29.1226 16.4501 28.6282 17.1701 28.7586 17.9251C28.8892 18.6802 29.5952 19.1842 30.3356 19.051Z",
            ),
          ]),
          svg.path([
            attribute("fill", "#151515"),
            attribute(
              "d",
              "M23.7248 20.7139C23.6399 20.7473 23.5623 20.7975 23.4963 20.8615C23.4305 20.9254 23.3775 21.0021 23.3408 21.0869C23.3039 21.1719 23.2838 21.2632 23.2815 21.356C23.2793 21.4488 23.295 21.5412 23.3278 21.6277C23.4133 21.8534 23.5415 22.0597 23.7052 22.235C23.869 22.4103 24.0649 22.5507 24.2819 22.6486C24.4987 22.7465 24.7323 22.8 24.9695 22.8059C25.2065 22.8115 25.4428 22.7696 25.664 22.6825C25.8852 22.5954 26.0877 22.4647 26.2594 22.2977C26.4311 22.1309 26.569 21.9309 26.6649 21.7099C26.7612 21.4885 26.8136 21.2498 26.8191 21.0078C26.8234 20.8205 26.7547 20.639 26.6279 20.5033C26.5009 20.3678 26.3264 20.2892 26.1426 20.2848C26.0517 20.2825 25.9613 20.2987 25.8764 20.3321C25.7915 20.3657 25.7139 20.4159 25.6481 20.48C25.5822 20.544 25.5294 20.6207 25.4927 20.7056C25.4559 20.7904 25.4358 20.882 25.4338 20.9747C25.4324 21.0307 25.4203 21.086 25.3979 21.1373C25.3756 21.1887 25.3433 21.2357 25.3035 21.2746C25.2635 21.3134 25.2165 21.3438 25.1651 21.364C25.1135 21.3843 25.0582 21.3942 25.0029 21.3929C24.9478 21.3915 24.8934 21.379 24.843 21.3562C24.7926 21.3334 24.7467 21.3007 24.7086 21.2601C24.6705 21.2193 24.6407 21.1712 24.6208 21.1185C24.588 21.032 24.5388 20.9528 24.4761 20.8857C24.4132 20.8185 24.3382 20.7645 24.2549 20.727C24.1718 20.6894 24.082 20.6689 23.9911 20.6666C23.9001 20.6643 23.8097 20.6804 23.7248 20.7139Z",
            ),
          ]),
        ]),
        svg.path([
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute("stroke-width", "2"),
          attribute("stroke", "#151515"),
          attribute(
            "d",
            "M23.5 48.9762V31.3691M5.87498 23.6806C5.29247 24.0097 4.80786 24.4874 4.47067 25.0648C4.13348 25.6423 3.95581 26.2988 3.95581 26.9673C3.95581 27.6358 4.13348 28.2924 4.47067 28.8698C4.80786 29.4473 5.29247 29.9249 5.87498 30.254L14.0608 34.871C14.55 35.1497 15.1035 35.2963 15.6666 35.2963C16.2298 35.2963 16.7833 35.1497 17.2725 34.871L39.1384 22.5681L41.125 23.6868C41.7075 24.0159 42.1921 24.4874 42.5293 25.0648C42.8665 25.6423 43.0441 26.2988 43.0441 26.9673C43.0441 27.6358 42.8665 28.2924 42.5293 28.8698C42.1921 29.4473 41.7075 29.9249 41.125 30.254L32.9196 34.871C32.4339 35.1497 31.8836 35.2964 31.3235 35.2964C30.7634 35.2964 30.2131 35.1497 29.7275 34.871L7.83333 22.5779M39.1666 31.3691V38.9402C39.1674 39.6786 38.9651 40.403 38.5817 41.0344C38.1984 41.6658 37.6488 42.1798 36.9929 42.5203L25.2429 48.5458C24.7045 48.8254 24.1067 48.9713 23.5 48.9713C22.8932 48.9713 22.2954 48.8254 21.7571 48.5458L10.0071 42.5203C9.35118 42.1798 8.80157 41.6658 8.41822 41.0344C8.03488 40.403 7.83255 39.6786 7.83331 38.9402V31.3691",
          ),
        ]),
      ]),
      svg.defs([], [
        element.element("clippath", [attribute.id("clip0_8_219")], [
          svg.rect([
            attribute("fill", "white"),
            attribute("height", "51"),
            attribute("width", "47"),
          ]),
        ]),
      ]),
    ],
  )
}

pub fn mode_switch() -> Element(Nil) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      attribute("class", "lightmode-switch-icon"),
    ],
    [
      svg.g([attribute("class", "lightmode-switch-icon-light")], [
        svg.path([
          attribute("stroke-width", "1.5"),
          attribute("stroke", "#151515"),
          attribute(
            "d",
            "M9.58614 2.90951C9.68306 2.47548 10.2559 2.37447 10.4954 2.74918L12.2219 5.45011C12.3871 5.70852 12.7438 5.75868 12.9739 5.55584L15.3804 3.43382C15.7141 3.13958 16.237 3.39494 16.2102 3.83901L16.0169 7.03605C15.9984 7.3425 16.2579 7.5931 16.5635 7.56396L19.7565 7.25948C20.1997 7.21722 20.4729 7.73154 20.1899 8.07512L18.1527 10.5482C17.9574 10.7853 18.0201 11.1408 18.2847 11.2968L21.0449 12.9239C21.4284 13.15 21.3475 13.7268 20.9166 13.8386L17.812 14.6446C17.5148 14.7217 17.3567 15.046 17.479 15.3276L18.754 18.2657C18.9311 18.6739 18.527 19.0927 18.1128 18.9303L15.1257 17.7593C14.8401 17.6474 14.5221 17.8166 14.4552 18.1159L13.7566 21.2444C13.6597 21.6784 13.0869 21.7794 12.8474 21.4047L11.1209 18.7038C10.9557 18.4454 10.5989 18.3952 10.3689 18.5981L7.96238 20.7201C7.6287 21.0143 7.10576 20.759 7.13261 20.3149L7.32584 17.1179C7.34436 16.8114 7.08491 16.5608 6.77929 16.59L3.58624 16.8944C3.1431 16.9367 2.86983 16.4224 3.15286 16.0788L5.19004 13.6057C5.38536 13.3686 5.32268 13.0131 5.05804 12.8571L2.29788 11.23C1.9144 11.0039 1.99529 10.4271 2.42616 10.3153L5.53078 9.50932C5.82794 9.43218 5.98603 9.10795 5.86382 8.82632L4.58878 5.88817C4.41168 5.48006 4.81574 5.06125 5.22994 5.22362L8.21709 6.39459C8.50263 6.50652 8.82071 6.33737 8.88755 6.03804L9.58614 2.90951Z",
          ),
        ]),
        svg.path([
          attribute("fill", "#151515"),
          attribute(
            "d",
            "M8.48966 13.2474C9.17993 13.1277 9.64086 12.4809 9.51917 11.8026C9.39748 11.1242 8.73927 10.6714 8.049 10.791C7.35873 10.9106 6.8978 11.5575 7.01949 12.2358C7.14117 12.914 7.7994 13.3671 8.48966 13.2474Z",
          ),
        ]),
        svg.path([
          attribute("fill", "#151515"),
          attribute(
            "d",
            "M14.715 12.4755C15.4052 12.3559 15.8662 11.709 15.7444 11.0307C15.6227 10.3524 14.9646 9.89953 14.2742 10.0192C13.584 10.1388 13.1231 10.7856 13.2447 11.4639C13.3665 12.1423 14.0247 12.5951 14.715 12.4755Z",
          ),
        ]),
        svg.path([
          attribute("fill", "#151515"),
          attribute(
            "d",
            "M10.5512 13.9695C10.4721 13.9995 10.3997 14.0446 10.3382 14.102C10.2768 14.1595 10.2274 14.2284 10.1931 14.3046C10.1587 14.3809 10.14 14.463 10.1379 14.5463C10.1358 14.6296 10.1505 14.7127 10.181 14.7904C10.2608 14.9931 10.3803 15.1785 10.533 15.336C10.6856 15.4935 10.8683 15.6196 11.0707 15.7076L11.0708 15.7077C11.2729 15.7957 11.4906 15.8436 11.7117 15.8489H11.7119H11.7122C11.9332 15.8539 12.153 15.8163 12.3593 15.7381H12.3594C12.5657 15.6598 12.7544 15.5423 12.9144 15.3923H12.9146V15.3922C13.0747 15.2423 13.2031 15.0628 13.2925 14.8642C13.3823 14.6654 13.4311 14.4509 13.4363 14.2335C13.4403 14.0652 13.3762 13.9022 13.258 13.7803C13.1396 13.6585 12.9769 13.5879 12.8056 13.5839C12.7208 13.5819 12.6364 13.5965 12.5573 13.6265C12.4782 13.6566 12.4058 13.7017 12.3444 13.7593C12.283 13.8168 12.2338 13.8857 12.1995 13.962C12.1653 14.0382 12.1466 14.1204 12.1446 14.2038C12.1433 14.2541 12.132 14.3038 12.1112 14.3498V14.35L12.111 14.3503C12.0902 14.3965 12.0603 14.4382 12.0232 14.4731C11.9858 14.5081 11.9421 14.5354 11.8941 14.5535L11.8938 14.5536C11.8456 14.5719 11.7944 14.5806 11.7429 14.5795C11.6916 14.5782 11.6408 14.5669 11.5938 14.5465H11.5935L11.5934 14.5463C11.5463 14.5258 11.504 14.4966 11.4685 14.4601V14.46C11.433 14.4233 11.4052 14.3803 11.3866 14.333C11.3561 14.2552 11.3102 14.1841 11.2517 14.1238C11.1931 14.0635 11.1232 14.0149 11.0455 13.9812C10.9679 13.9474 10.8843 13.929 10.7995 13.9269C10.7147 13.9249 10.6304 13.9393 10.5512 13.9695Z",
          ),
        ]),
      ]),
      svg.g([attribute("class", "lightmode-switch-icon-dark")], [
        svg.path([
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute("stroke-width", "1.5"),
          attribute("stroke", "#151515"),
          attribute(
            "d",
            "M3.72755 13.2155C9.34456 13.2155 13.898 8.66199 13.898 3.04498C13.898 2.37396 14.5005 1.82267 15.1306 2.05342C19.0246 3.47949 21.8035 7.21849 21.8035 11.6065C21.8035 17.2236 17.25 21.777 11.633 21.777C7.24502 21.777 3.50606 18.9982 2.07995 15.1043C1.71398 14.105 2.66339 13.2155 3.72755 13.2155Z",
          ),
        ]),
        svg.path([
          attribute("fill", "#151515"),
          attribute(
            "d",
            "M9.48966 16.2474C10.1799 16.1277 10.6409 15.4809 10.5192 14.8026C10.3975 14.1242 9.73927 13.6714 9.049 13.791C8.35873 13.9106 7.8978 14.5575 8.01949 15.2358C8.14117 15.914 8.7994 16.3671 9.48966 16.2474Z",
          ),
        ]),
        svg.path([
          attribute("fill", "#151515"),
          attribute(
            "d",
            "M15.715 15.4755C16.4052 15.3559 16.8662 14.709 16.7444 14.0307C16.6227 13.3524 15.9646 12.8995 15.2742 13.0192C14.584 13.1388 14.1231 13.7856 14.2447 14.4639C14.3665 15.1423 15.0247 15.5951 15.715 15.4755Z",
          ),
        ]),
        svg.path([
          attribute("fill", "#151515"),
          attribute(
            "d",
            "M11.5512 16.9695C11.4721 16.9995 11.3997 17.0446 11.3382 17.102C11.2768 17.1595 11.2274 17.2284 11.1931 17.3046C11.1587 17.3809 11.14 17.463 11.1379 17.5463C11.1358 17.6296 11.1505 17.7127 11.181 17.7904C11.2608 17.9931 11.3803 18.1785 11.533 18.336C11.6856 18.4935 11.8683 18.6196 12.0707 18.7076L12.0708 18.7077C12.2729 18.7957 12.4906 18.8436 12.7117 18.8489H12.7119H12.7122C12.9332 18.8539 13.153 18.8163 13.3593 18.7381H13.3594C13.5657 18.6598 13.7544 18.5423 13.9144 18.3923H13.9146V18.3922C14.0747 18.2423 14.2031 18.0628 14.2925 17.8642C14.3823 17.6654 14.4311 17.4509 14.4363 17.2335C14.4403 17.0652 14.3762 16.9022 14.258 16.7803C14.1396 16.6585 13.9769 16.5879 13.8056 16.5839C13.7208 16.5819 13.6364 16.5965 13.5573 16.6265C13.4782 16.6566 13.4058 16.7017 13.3444 16.7593C13.283 16.8168 13.2338 16.8857 13.1995 16.962C13.1653 17.0382 13.1466 17.1204 13.1446 17.2038C13.1433 17.2541 13.132 17.3038 13.1112 17.3498V17.35L13.111 17.3503C13.0902 17.3965 13.0603 17.4382 13.0232 17.4731C12.9858 17.5081 12.9421 17.5354 12.8941 17.5535L12.8938 17.5536C12.8456 17.5719 12.7944 17.5806 12.7429 17.5795C12.6916 17.5782 12.6408 17.5669 12.5938 17.5465H12.5935L12.5934 17.5463C12.5463 17.5258 12.504 17.4966 12.4685 17.4601V17.46C12.433 17.4233 12.4052 17.3803 12.3866 17.333C12.3561 17.2552 12.3102 17.1841 12.2517 17.1238C12.1931 17.0635 12.1232 17.0149 12.0455 16.9812C11.9679 16.9474 11.8843 16.929 11.7995 16.9269C11.7147 16.9249 11.6304 16.9393 11.5512 16.9695Z",
          ),
        ]),
      ]),
    ],
  )
}

pub fn git_tree() -> Element(Nil) {
  svg.svg(
    [
      attribute("viewBox", "0 0 448 512"),
      attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute(
          "d",
          "M80 112a32 32 0 1 0 0-64 32 32 0 1 0 0 64zm80-32c0 35.8-23.5 66.1-56 76.3l0 99.7c20.1-15.1 45-24 72-24l96 0c39.8 0 72-32.2 72-72l0-3.7c-32.5-10.2-56-40.5-56-76.3c0-44.2 35.8-80 80-80s80 35.8 80 80c0 35.8-23.5 66.1-56 76.3l0 3.7c0 66.3-53.7 120-120 120l-96 0c-39.8 0-72 32.2-72 72l0 3.7c32.5 10.2 56 40.5 56 76.3c0 44.2-35.8 80-80 80s-80-35.8-80-80c0-35.8 23.5-66.1 56-76.3l0-3.7 0-195.7C23.5 146.1 0 115.8 0 80C0 35.8 35.8 0 80 0s80 35.8 80 80zm240 0a32 32 0 1 0 -64 0 32 32 0 1 0 64 0zM80 464a32 32 0 1 0 0-64 32 32 0 1 0 0 64z",
        ),
      ]),
    ],
  )
}

pub fn docs() -> Element(Nil) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 20 20"),
    ],
    [
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.66667"),
        attribute(
          "d",
          "M3.33331 16.25V3.75001C3.33331 3.19747 3.55281 2.66757 3.94351 2.27687C4.33421 1.88617 4.86411 1.66667 5.41665 1.66667H15.8333C16.0543 1.66667 16.2663 1.75447 16.4226 1.91075C16.5788 2.06703 16.6666 2.27899 16.6666 2.50001V17.5C16.6666 17.721 16.5788 17.933 16.4226 18.0893C16.2663 18.2455 16.0543 18.3333 15.8333 18.3333H5.41665C4.86411 18.3333 4.33421 18.1138 3.94351 17.7231C3.55281 17.3324 3.33331 16.8025 3.33331 16.25ZM3.33331 16.25C3.33331 15.6975 3.55281 15.1676 3.94351 14.7769C4.33421 14.3862 4.86411 14.1667 5.41665 14.1667H16.6666",
        ),
      ]),
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.66667"),
        attribute("d", "M6.66669 9.16667H13.3334"),
      ]),
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.66667"),
        attribute("d", "M6.66669 5.83333H11.6667"),
      ]),
    ],
  )
}

pub fn hex() -> Element(Nil) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 20 20"),
    ],
    [
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.66667"),
        attribute(
          "d",
          "M17.5 13.3333V6.66667C17.4997 6.3744 17.4225 6.08735 17.2763 5.83431C17.13 5.58127 16.9198 5.37114 16.6667 5.225L10.8333 1.89167C10.58 1.74539 10.2926 1.66838 10 1.66838C9.70744 1.66838 9.42003 1.74539 9.16667 1.89167L3.33333 5.225C3.08022 5.37114 2.86998 5.58127 2.72372 5.83431C2.57745 6.08735 2.5003 6.3744 2.5 6.66667V13.3333C2.5003 13.6256 2.57745 13.9127 2.72372 14.1657C2.86998 14.4187 3.08022 14.6289 3.33333 14.775L9.16667 18.1083C9.42003 18.2546 9.70744 18.3316 10 18.3316C10.2926 18.3316 10.58 18.2546 10.8333 18.1083L16.6667 14.775C16.9198 14.6289 17.13 14.4187 17.2763 14.1657C17.4225 13.9127 17.4997 13.6256 17.5 13.3333Z",
        ),
      ]),
    ],
  )
}

pub fn git() -> Element(Nil) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 20 20"),
    ],
    [
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.66667"),
        attribute("d", "M5 2.5V12.5"),
      ]),
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.66667"),
        attribute(
          "d",
          "M15 7.5C16.3807 7.5 17.5 6.38071 17.5 5C17.5 3.61929 16.3807 2.5 15 2.5C13.6193 2.5 12.5 3.61929 12.5 5C12.5 6.38071 13.6193 7.5 15 7.5Z",
        ),
      ]),
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.66667"),
        attribute(
          "d",
          "M5 17.5C6.38071 17.5 7.5 16.3807 7.5 15C7.5 13.6193 6.38071 12.5 5 12.5C3.61929 12.5 2.5 13.6193 2.5 15C2.5 16.3807 3.61929 17.5 5 17.5Z",
        ),
      ]),
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.66667"),
        attribute(
          "d",
          "M15 7.5C15 9.48912 14.2098 11.3968 12.8033 12.8033C11.3968 14.2098 9.48912 15 7.5 15",
        ),
      ]),
    ],
  )
}

pub fn search() -> Element(Nil) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      attribute("stroke", "currentColor"),
      class("search-icon"),
    ],
    [
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "2"),
        attribute(
          "d",
          "M11 19C15.4183 19 19 15.4183 19 11C19 6.58172 15.4183 3 11 3C6.58172 3 3 6.58172 3 11C3 15.4183 6.58172 19 11 19Z",
        ),
      ]),
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "2"),
        attribute("d", "M21 21L16.7 16.7"),
      ]),
    ],
  )
}

pub fn icon_moon() -> Element(Nil) {
  svg.svg(
    [attribute.id("icon-moon"), attribute.attribute("viewBox", "0 0 24 24")],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M21.996 12.882c0.022-0.233-0.038-0.476-0.188-0.681-0.325-0.446-0.951-0.544-1.397-0.219-0.95 0.693-2.060 1.086-3.188 1.162-1.368 0.092-2.765-0.283-3.95-1.158-1.333-0.985-2.139-2.415-2.367-3.935s0.124-3.124 1.109-4.456c0.142-0.191 0.216-0.435 0.191-0.691-0.053-0.55-0.542-0.952-1.092-0.898-2.258 0.22-4.314 1.18-5.895 2.651-1.736 1.615-2.902 3.847-3.137 6.386-0.254 2.749 0.631 5.343 2.266 7.311s4.022 3.313 6.772 3.567 5.343-0.631 7.311-2.266 3.313-4.022 3.567-6.772zM19.567 14.674c-0.49 1.363-1.335 2.543-2.416 3.441-1.576 1.309-3.648 2.016-5.848 1.813s-4.108-1.278-5.417-2.854-2.016-3.648-1.813-5.848c0.187-2.032 1.117-3.814 2.507-5.106 0.782-0.728 1.71-1.3 2.731-1.672-0.456 1.264-0.577 2.606-0.384 3.899 0.303 2.023 1.38 3.934 3.156 5.247 1.578 1.167 3.448 1.668 5.272 1.545 0.752-0.050 1.496-0.207 2.21-0.465z",
        ),
      ]),
    ],
  )
}

pub fn icon_sun() -> Element(Nil) {
  svg.svg(
    [attribute.id("icon-sun"), attribute.attribute("viewBox", "0 0 24 24")],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M18 12c0-1.657-0.673-3.158-1.757-4.243s-2.586-1.757-4.243-1.757-3.158 0.673-4.243 1.757-1.757 2.586-1.757 4.243 0.673 3.158 1.757 4.243 2.586 1.757 4.243 1.757 3.158-0.673 4.243-1.757 1.757-2.586 1.757-4.243zM16 12c0 1.105-0.447 2.103-1.172 2.828s-1.723 1.172-2.828 1.172-2.103-0.447-2.828-1.172-1.172-1.723-1.172-2.828 0.447-2.103 1.172-2.828 1.723-1.172 2.828-1.172 2.103 0.447 2.828 1.172 1.172 1.723 1.172 2.828zM11 1v2c0 0.552 0.448 1 1 1s1-0.448 1-1v-2c0-0.552-0.448-1-1-1s-1 0.448-1 1zM11 21v2c0 0.552 0.448 1 1 1s1-0.448 1-1v-2c0-0.552-0.448-1-1-1s-1 0.448-1 1zM3.513 4.927l1.42 1.42c0.391 0.391 1.024 0.391 1.414 0s0.391-1.024 0-1.414l-1.42-1.42c-0.391-0.391-1.024-0.391-1.414 0s-0.391 1.024 0 1.414zM17.653 19.067l1.42 1.42c0.391 0.391 1.024 0.391 1.414 0s0.391-1.024 0-1.414l-1.42-1.42c-0.391-0.391-1.024-0.391-1.414 0s-0.391 1.024 0 1.414zM1 13h2c0.552 0 1-0.448 1-1s-0.448-1-1-1h-2c-0.552 0-1 0.448-1 1s0.448 1 1 1zM21 13h2c0.552 0 1-0.448 1-1s-0.448-1-1-1h-2c-0.552 0-1 0.448-1 1s0.448 1 1 1zM4.927 20.487l1.42-1.42c0.391-0.391 0.391-1.024 0-1.414s-1.024-0.391-1.414 0l-1.42 1.42c-0.391 0.391-0.391 1.024 0 1.414s1.024 0.391 1.414 0zM19.067 6.347l1.42-1.42c0.391-0.391 0.391-1.024 0-1.414s-1.024-0.391-1.414 0l-1.42 1.42c-0.391 0.391-0.391 1.024 0 1.414s1.024 0.391 1.414 0z",
        ),
      ]),
    ],
  )
}

pub fn icon_toggle_left() -> Element(Nil) {
  svg.svg(
    [
      attribute.id("icon-toggle-left"),
      attribute.attribute("viewBox", "0 0 24 24"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M8 4c-2.209 0-4.21 0.897-5.657 2.343s-2.343 3.448-2.343 5.657 0.897 4.21 2.343 5.657 3.448 2.343 5.657 2.343h8c2.209 0 4.21-0.897 5.657-2.343s2.343-3.448 2.343-5.657-0.897-4.21-2.343-5.657-3.448-2.343-5.657-2.343zM8 6h8c1.657 0 3.156 0.67 4.243 1.757s1.757 2.586 1.757 4.243-0.67 3.156-1.757 4.243-2.586 1.757-4.243 1.757h-8c-1.657 0-3.156-0.67-4.243-1.757s-1.757-2.586-1.757-4.243 0.67-3.156 1.757-4.243 2.586-1.757 4.243-1.757zM12 12c0-1.104-0.449-2.106-1.172-2.828s-1.724-1.172-2.828-1.172-2.106 0.449-2.828 1.172-1.172 1.724-1.172 2.828 0.449 2.106 1.172 2.828 1.724 1.172 2.828 1.172 2.106-0.449 2.828-1.172 1.172-1.724 1.172-2.828zM10 12c0 0.553-0.223 1.051-0.586 1.414s-0.861 0.586-1.414 0.586-1.051-0.223-1.414-0.586-0.586-0.861-0.586-1.414 0.223-1.051 0.586-1.414 0.861-0.586 1.414-0.586 1.051 0.223 1.414 0.586 0.586 0.861 0.586 1.414z",
        ),
      ]),
    ],
  )
}

pub fn icon_toggle_right() -> Element(Nil) {
  svg.svg(
    [
      attribute.id("icon-toggle-right"),
      attribute.attribute("viewBox", "0 0 24 24"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M8 4c-2.209 0-4.21 0.897-5.657 2.343s-2.343 3.448-2.343 5.657 0.897 4.21 2.343 5.657 3.448 2.343 5.657 2.343h8c2.209 0 4.21-0.897 5.657-2.343s2.343-3.448 2.343-5.657-0.897-4.21-2.343-5.657-3.448-2.343-5.657-2.343zM8 6h8c1.657 0 3.156 0.67 4.243 1.757s1.757 2.586 1.757 4.243-0.67 3.156-1.757 4.243-2.586 1.757-4.243 1.757h-8c-1.657 0-3.156-0.67-4.243-1.757s-1.757-2.586-1.757-4.243 0.67-3.156 1.757-4.243 2.586-1.757 4.243-1.757zM20 12c0-1.104-0.449-2.106-1.172-2.828s-1.724-1.172-2.828-1.172-2.106 0.449-2.828 1.172-1.172 1.724-1.172 2.828 0.449 2.106 1.172 2.828 1.724 1.172 2.828 1.172 2.106-0.449 2.828-1.172 1.172-1.724 1.172-2.828zM18 12c0 0.553-0.223 1.051-0.586 1.414s-0.861 0.586-1.414 0.586-1.051-0.223-1.414-0.586-0.586-0.861-0.586-1.414 0.223-1.051 0.586-1.414 0.861-0.586 1.414-0.586 1.051 0.223 1.414 0.586 0.586 0.861 0.586 1.414z",
        ),
      ]),
    ],
  )
}

"use client";

import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { gradient } from "@/components/Gradient";
import { useEffect } from "react";

export default function Home() {
  useEffect(() => {
    gradient.initGradient("#gradient-canvas");
  }, []);

  return (
    <AnimatePresence>
      <div className="min-h-[100vh] sm:min-h-screen w-screen flex flex-col relative bg-[#F2F3F5] font-inter overflow-hidden">
        <svg
          style={{ filter: "contrast(125%) brightness(110%)" }}
          className="fixed z-[1] w-full h-full opacity-[35%]"
        >
          <filter id="noise">
            <feTurbulence></feTurbulence>
            <feColorMatrix type="saturate" values="0"></feColorMatrix>
          </filter>
          <rect width="100%" height="100%" filter="url(#noise)"></rect>
        </svg>
        <main className="flex flex-col justify-center h-[90%] static md:fixed w-screen overflow-hidden grid-rows-[1fr_repeat(3,auto)_1fr] z-[100] pt-[30px] pb-[320px] px-4 md:px-20 md:py-0">
          <motion.img
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              delay: 0.15,
              duration: 0.95,
              ease: [0.165, 0.84, 0.44, 1],
            }}
            className="block w-[200px] md:ml-[-10px] row-start-2 mb-8 md:mb-6"
            src="cloud-logo.png"
            alt="cloud Brand Logo"
          ></motion.img>

          <motion.h3
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              delay: 0.15,
              duration: 0.95,
              ease: [0.165, 0.84, 0.44, 1],
            }}
            className="relative md:ml-[-10px] md:mb-[37px] font-extrabold text-[12vw] md:text-[80px] font-inter text-[#000000] leading-[0.9] tracking-[-2px] z-[100]"
          >
            Document{" "}
            <span className="text-[#1E9BD7] md:text-[80px]">Service</span>
          </motion.h3>
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              delay: 0.15,
              duration: 0.95,
              ease: [0.165, 0.84, 0.44, 1],
            }}
            className="flex flex-row justify-center z-20 mx-0 mb-0 mt-8 md:mt-0 md:mb-[35px] max-w-2xl md:space-x-8"
          >
            <div className="w-1/2">
              <h2 className="flex items-center font-semibold text-[1em] text-[#1a2b3b]">
                Research
              </h2>
              <p className="text-[14px] leading-[20px] text-[#1a2b3b] font-normal">
                Full access to all cloud&apos;s documents ever uploaded to
                the platform.
              </p>

              <div className="flex gap-[15px] pt-10 mt-8 md:mt-0 md:ml-[-10px]">
                <motion.div
                  initial={{ opacity: 0, y: 40 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{
                    delay: 0.55,
                    duration: 0.55,
                    ease: [0.075, 0.82, 0.965, 1],
                  }}
                >
                  <Link
                    href="/search"
                    className="group rounded-full px-4 py-2 text-[13px] font-semibold transition-all flex items-center justify-center bg-[#f5f7f9] text-[#1E2B3A] no-underline active:scale-95 scale-100 duration-75"
                    style={{
                      boxShadow: "0 1px 1px #0c192714, 0 1px 3px #0c192724",
                    }}
                  >
                    <span className="mr-2"> Search the database </span>

                    <svg
                      className="w-5 h-5 group-hover:-rotate-45 transition-all duration-300"
                      viewBox="0 0 24 24"
                      fill="none"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <path
                        d="M13.75 6.75L19.25 12L13.75 17.25"
                        stroke="#1E2B3A"
                        strokeWidth="1.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                      <path
                        d="M19 12H4.75"
                        stroke="#1E2B3A"
                        strokeWidth="1.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                  </Link>
                </motion.div>
              </div>
            </div>
            <div className="w-1/2">
              <h2 className="flex items-center font-semibold text-[1em] text-[#1a2b3b]">
                Artificial Intelligence
              </h2>
              <p className="text-[14px] leading-[20px] text-[#1a2b3b] font-normal">
                Ask the in-house AI to answer all your documents related
                questions.
                <em> (Coming soon!)</em>
              </p>
              <div className="flex gap-[15px] pt-10 mt-8 md:mt-0 md:ml-[-10px]">
                <motion.div
                  initial={{ opacity: 0, y: 40 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{
                    delay: 0.55,
                    duration: 0.55,
                    ease: [0.075, 0.82, 0.965, 1],
                  }}
                >
                  <Link
                    href="/upload"
                    className="group rounded-full px-4 py-2 text-[13px] font-semibold transition-all flex items-center justify-center bg-[#f5f7f9] text-[#1E2B3A] no-underline active:scale-95 scale-100 duration-75"
                    style={{
                      boxShadow: "0 1px 1px #0c192714, 0 1px 3px #0c192724",
                    }}
                  >
                    <span className="mr-2"> Upload a new document </span>

                    <svg
                      className="w-5 h-5 group-hover:-rotate-45 transition-all duration-300"
                      viewBox="0 0 24 24"
                      fill="none"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <path
                        d="M13.75 6.75L19.25 12L13.75 17.25"
                        stroke="#1E2B3A"
                        strokeWidth="1.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                      <path
                        d="M19 12H4.75"
                        stroke="#1E2B3A"
                        strokeWidth="1.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                  </Link>
                </motion.div>
              </div>
            </div>
          </motion.div>
        </main>

        <div
          className="fixed top-0 right-0 w-[80%] md:w-1/2 h-screen"
          style={{
            clipPath:
              "polygon(100px 0,100% 0,calc(100% + 225px) 100%, 480px 100%)",
          }}
        ></div>

        <motion.canvas
          initial={{
            filter: "blur(20px)",
          }}
          animate={{
            filter: "blur(0px)",
          }}
          transition={{
            duration: 1,
            ease: [0.075, 0.82, 0.965, 1],
          }}
          style={{
            clipPath:
              "polygon(100px 0,100% 0,calc(100% + 225px) 100%, 480px 100%)",
          }}
          id="gradient-canvas"
          data-transition-in
          className="z-50 fixed top-0 right-[-2px] w-[80%] md:w-1/2 h-screen bg-[#c3e4ff]"
        ></motion.canvas>
        <div className="h-[40px] bg-[#000000] fixed bottom-0 z-50 w-full flex flex-row items-center justify-evenly"></div>
      </div>
    </AnimatePresence>
  );
}

import { AnimatePresence, motion } from "framer-motion";
import { RadioGroup } from "@headlessui/react";
import Link from "next/link";
import { SetStateAction, useState } from "react";

import TableComponent from "@/components/ui_steps/Table";
import ChatInterface from "@/components/ui_steps/ChatInterface";
import CustomFileInput from "@/components/FileDropzone";

import { useSession, signIn } from "next-auth/react";

const groups = [
  {
    id: "ab_cloud",
    name: "The whole company",
    description: "cloud",
  },
  {
    id: "just_me",
    name: "Just me",
    description: "Only visible to you",
  },
];

function classNames(...classes: string[]) {
  return classes.filter(Boolean).join(" ");
}

export default function UploadPage() {
  const [selectedGroup, setSelectedGroup] = useState(groups[0]);
  const [step, setStep] = useState(1);
  const [tags, setTags] = useState("");
  const [companyName, setCompanyName] = useState("");
  const [preferredDocName, setPreferredDocName] = useState("");
  const [sector, setSector] = useState("");
  const [year, setYear] = useState("");

  const [companyNameError, setCompanyNameError] = useState(false);
  const [preferredDocNameError, setPreferredDocNameError] = useState(false);
  const [sectorError, setSectorError] = useState(false);
  const [yearError, setYearError] = useState(false);

  const handleContinue = () => {
    const parsedYear = parseInt(year, 10);

    const validateInput = (
      inputValue: string,
      setError: {
        (value: SetStateAction<boolean>): void;
        (value: SetStateAction<boolean>): void;
        (value: SetStateAction<boolean>): void;
        (arg0: boolean): void;
      }
    ) => {
      if (!inputValue) {
        setError(true);
        return true;
      }
      setError(false);
      return false;
    };

    let hasError = false;

    hasError = validateInput(companyName, setCompanyNameError) || hasError;
    hasError =
      validateInput(preferredDocName, setPreferredDocNameError) || hasError;
    hasError = validateInput(sector, setSectorError) || hasError;

    if (!year || isNaN(parsedYear) || parsedYear < 1900 || parsedYear > 2100) {
      setYearError(true);
      hasError = true;
    } else {
      setYearError(false);
    }

    if (!hasError) {
      setStep(2);
    }
  };

  const { data: _session, status } = useSession();

  if (status === "loading") {
    return <p>Hang on there...</p>;
  }

  if (status === "authenticated") {
    return (
      <AnimatePresence>
        {step === 3 ? (
          <div className="w-full min-h-screen flex flex-col px-4 pt-2 pb-8 md:px-8 md:py-2 bg-[#FCFCFC] relative overflow-x-hidden">
            <div className="h-full w-full items-center flex flex-col mt-[10vh]">
              <div className="w-full flex flex-col max-w-[1080px] mx-auto justify-center">
                <CustomFileInput
                  selectedGroup={selectedGroup}
                  companyName={companyName}
                  preferredDocName={preferredDocName}
                  tags={tags}
                  sector={sector}
                  year={year}
                />

                <div className="flex flex-row space-x-4 mt-8 justify-end">
                  <button
                    onClick={() => setStep(2)}
                    className="group max-w-[200px] rounded-full px-4 py-2 text-[13px] font-semibold transition-all flex items-center justify-center bg-[#f5f7f9] text-[#1E2B3A] no-underline active:scale-95 scale-100 duration-75"
                    style={{
                      boxShadow: "0 1px 1px #0c192714, 0 1px 3px #0c192724",
                    }}
                  >
                    Previous Step
                  </button>
                  <Link
                    href="/search"
                    className="group rounded-full pl-[8px] min-w-[180px] pr-4 py-2 text-[13px] font-semibold transition-all flex items-center justify-center bg-[#1E9BD7] text-white hover:[linear-gradient(0deg, rgba(255, 255, 255, 0.1), rgba(255, 255, 255, 0.1)), #0D2247] no-underline flex gap-x-2  active:scale-95 scale-100 duration-75"
                    style={{
                      boxShadow:
                        "0px 1px 4px rgba(13, 34, 71, 0.17), inset 0px 0px 0px 1px #1E9BD7, inset 0px 0px 0px 2px rgba(255, 255, 255, 0.1)",
                    }}
                  >
                    Done
                  </Link>
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="flex flex-col md:flex-row w-full md:overflow-hidden">
            <div className="w-full min-h-[60vh] md:w-1/2 md:h-screen flex flex-col px-4 pt-2 pb-8 md:px-0 md:py-2 bg-[#FCFCFC] justify-center">
              <div className="h-full w-full items-center justify-center flex flex-col">
                {step === 1 ? (
                  <motion.div
                    initial={{ opacity: 0, y: 40 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -40 }}
                    key="step-1"
                    transition={{
                      duration: 0.95,
                      ease: [0.165, 0.84, 0.44, 1],
                    }}
                    className="max-w-lg mx-auto px-4 lg:px-0"
                  >
                    <h2 className="text-4xl font-bold text-[#1E2B3A]">
                      Create your metadata
                    </h2>

                    <div className="mt-4">
                      <label
                        htmlFor="companyName"
                        className="text-[14px] leading-[20px] text-[#1a2b3b] font-normal my-4"
                      >
                        Company/Deal name
                      </label>

                      <div className="relative mt-1">
                        <div className="relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md focus:outline-none sm:text-sm">
                          <input
                            type="text"
                            id="companyName"
                            value={companyName}
                            onChange={(e) => {
                              setCompanyName(e.target.value);
                              setCompanyNameError(false);
                            }}
                            className="w-full border-none py-2 ml-2 pr-10 text-sm leading-5 text-gray-900 focus:border-none focus:outline-none"
                            placeholder="Tesla Inc."
                            required
                          />
                        </div>
                      </div>
                      {companyNameError && (
                        <p className="text-red-500 text-xs mt-1">
                          Company/Deal name is required.
                        </p>
                      )}
                    </div>

                    <div className="mt-4">
                      <label
                        htmlFor="preferredDocName"
                        className="text-[14px] leading-[20px] text-[#1a2b3b] font-normal my-4"
                      >
                        Preferred document name
                      </label>

                      <div className="relative mt-1">
                        <div className="relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md focus:outline-none sm:text-sm">
                          <input
                            type="text"
                            id="preferredDocName"
                            value={preferredDocName}
                            onChange={(e) => {
                              setPreferredDocName(e.target.value);
                              setPreferredDocNameError(false);
                            }}
                            className="w-full border-none py-2 ml-2 pr-10 text-sm leading-5 text-gray-900 focus:border-none focus:outline-none"
                            placeholder="10-K"
                            required
                          />
                        </div>
                      </div>
                      {preferredDocNameError && (
                        <p className="text-red-500 text-xs mt-1">
                          Preferred document name is required.
                        </p>
                      )}
                    </div>

                    <div className="mt-4">
                      <label
                        htmlFor="sector"
                        className="text-[14px] leading-[20px] text-[#1a2b3b] font-normal my-4"
                      >
                        Sector
                      </label>

                      <div className="relative mt-1">
                        <div className="relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md focus:outline-none sm:text-sm">
                          <input
                            type="text"
                            id="sector"
                            value={sector}
                            onChange={(e) => {
                              setSector(e.target.value);
                              setSectorError(false);
                            }}
                            className="w-full border-none py-2 ml-2 pr-10 text-sm leading-5 text-gray-900 focus:border-none focus:outline-none"
                            placeholder="Financial Services"
                            required
                          />
                        </div>
                      </div>
                      {sectorError && (
                        <p className="text-red-500 text-xs mt-1">
                          Sector is required.
                        </p>
                      )}
                    </div>

                    <div className="mt-4">
                      <label
                        htmlFor="sector"
                        className="text-[14px] leading-[20px] text-[#1a2b3b] font-normal my-4"
                      >
                        Year
                      </label>

                      <div className="relative mt-1">
                        <div className="relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md focus:outline-none sm:text-sm">
                          <input
                            type="number"
                            id="year"
                            min="1900"
                            max="2100"
                            value={year}
                            onChange={(e) => {
                              setYear(e.target.value);
                              setYearError(false);
                            }}
                            className="w-full border-none py-2 ml-2 pr-10 text-sm leading-5 text-gray-900 focus:border-none focus:outline-none"
                            placeholder="2023"
                            required
                          />
                        </div>
                      </div>
                      {yearError && (
                        <p className="text-red-500 text-xs mt-1">
                          Year is required.
                        </p>
                      )}
                    </div>

                    <div className="mt-4">
                      <label
                        htmlFor="tags"
                        className="text-[14px] leading-[20px] text-[#1a2b3b] font-normal my-4"
                      >
                        Tags
                      </label>
                      <div className="relative mt-1">
                        <div className="relative w-full cursor-default overflow-hidden rounded-lg bg-white text-left shadow-md focus:outline-none sm:text-sm">
                          <input
                            type="text"
                            id="tags"
                            value={tags}
                            onChange={(e) => setTags(e.target.value)}
                            className="w-full border-none py-2 ml-2 pr-10 text-sm leading-5 text-gray-900 focus:border-none focus:outline-none"
                            placeholder="#finance, #acquisition, #merger (optional)"
                          />
                        </div>
                      </div>
                    </div>

                    <div className="flex gap-[15px] justify-end mt-8">
                      <div>
                        <Link
                          href="/"
                          className="group rounded-full px-4 py-2 text-[13px] font-semibold transition-all flex items-center justify-center bg-[#f5f7f9] text-[#1E2B3A] no-underline active:scale-95 scale-100 duration-75"
                          style={{
                            boxShadow:
                              "0 1px 1px #0c192714, 0 1px 3px #0c192724",
                          }}
                        >
                          Back to home
                        </Link>
                      </div>
                      <div>
                        <button
                          onClick={handleContinue}
                          className="group rounded-full px-4 py-2 text-[13px] font-semibold transition-all flex items-center justify-center bg-[#1E9BD7] text-white hover:[linear-gradient(0deg, rgba(255, 255, 255, 0.1), rgba(255, 255, 255, 0.1)), #1E9BD7] no-underline flex gap-x-2  active:scale-95 scale-100 duration-75"
                          style={{
                            boxShadow:
                              "0px 1px 4px rgba(13, 34, 71, 0.17), inset 0px 0px 0px 1px #1E9BD7, inset 0px 0px 0px 2px rgba(255, 255, 255, 0.1)",
                          }}
                        >
                          <span> Continue </span>
                          <svg
                            className="w-5 h-5 group-hover:-rotate-45 transition-all duration-300"
                            viewBox="0 0 24 24"
                            fill="none"
                            xmlns="http://www.w3.org/2000/svg"
                          >
                            <path
                              d="M13.75 6.75L19.25 12L13.75 17.25"
                              stroke="#FFF"
                              strokeWidth="1.5"
                              strokeLinecap="round"
                              strokeLinejoin="round"
                            />
                            <path
                              d="M19 12H4.75"
                              stroke="#FFF"
                              strokeWidth="1.5"
                              strokeLinecap="round"
                              strokeLinejoin="round"
                            />
                          </svg>
                        </button>
                      </div>
                    </div>
                  </motion.div>
                ) : step === 2 ? (
                  <motion.div
                    initial={{ opacity: 0, y: 40 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -40 }}
                    key="step-2"
                    transition={{
                      duration: 0.95,
                      ease: [0.165, 0.84, 0.44, 1],
                    }}
                    className="max-w-lg mx-auto px-4 lg:px-0"
                  >
                    <h2 className="text-4xl font-bold text-[#1E2B3A]">
                      Who should be able to access this document?
                    </h2>
                    <p className="text-[14px] leading-[20px] text-[#1a2b3b] font-normal my-4">
                      Make sure you&apos;re selecting the correct option as
                      it&apos;s not currently possible to update it later.
                    </p>
                    <div>
                      <RadioGroup
                        value={selectedGroup}
                        onChange={setSelectedGroup}
                      >
                        <RadioGroup.Label className="sr-only">
                          Group
                        </RadioGroup.Label>
                        <div className="space-y-4">
                          {groups.map((group) => (
                            <RadioGroup.Option
                              key={group.name}
                              value={group}
                              className={({ checked, active }) =>
                                classNames(
                                  checked
                                    ? "border-transparent"
                                    : "border-gray-300",
                                  active
                                    ? "border-blue-500 ring-2 ring-blue-200"
                                    : "",
                                  "relative cursor-pointer rounded-lg border bg-white px-6 py-4 shadow-sm focus:outline-none flex justify-between"
                                )
                              }
                            >
                              {({ active, checked }) => (
                                <>
                                  <span className="flex items-center">
                                    <span className="flex flex-col text-sm">
                                      <RadioGroup.Label
                                        as="span"
                                        className="font-medium text-gray-900"
                                      >
                                        {group.name}
                                      </RadioGroup.Label>
                                      <RadioGroup.Description
                                        as="span"
                                        className="text-gray-500"
                                      >
                                        <span className="block">
                                          {group.description}
                                        </span>
                                      </RadioGroup.Description>
                                    </span>
                                  </span>
                                  <RadioGroup.Description
                                    as="span"
                                    className="flex text-sm ml-4 mt-0 flex-col text-right items-center justify-center"
                                  >
                                    {group.description === "cloud" ? (
                                      <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        strokeWidth="1.5"
                                        stroke="currentColor"
                                        className="w-6 h-6"
                                      >
                                        <path
                                          strokeLinecap="round"
                                          strokeLinejoin="round"
                                          d="M13.5 10.5V6.75a4.5 4.5 0 119 0v3.75M3.75 21.75h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H3.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z"
                                        />
                                      </svg>
                                    ) : (
                                      <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        strokeWidth="1.5"
                                        stroke="currentColor"
                                        className="w-6 h-6"
                                      >
                                        <path
                                          strokeLinecap="round"
                                          strokeLinejoin="round"
                                          d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z"
                                        />
                                      </svg>
                                    )}
                                  </RadioGroup.Description>
                                  <span
                                    className={classNames(
                                      active ? "border" : "border-2",
                                      checked
                                        ? "border-blue-500"
                                        : "border-transparent",
                                      "pointer-events-none absolute -inset-px rounded-lg"
                                    )}
                                    aria-hidden="true"
                                  />
                                </>
                              )}
                            </RadioGroup.Option>
                          ))}
                        </div>
                      </RadioGroup>
                    </div>
                    <div className="flex gap-[15px] justify-end mt-8">
                      <div>
                        <button
                          onClick={() => setStep(1)}
                          className="group rounded-full px-4 py-2 text-[13px] font-semibold transition-all flex items-center justify-center bg-[#f5f7f9] text-[#1E2B3A] no-underline active:scale-95 scale-100 duration-75"
                          style={{
                            boxShadow:
                              "0 1px 1px #0c192714, 0 1px 3px #0c192724",
                          }}
                        >
                          Previous step
                        </button>
                      </div>
                      <div>
                        <button
                          onClick={() => {
                            setStep(3);
                          }}
                          className="group rounded-full px-4 py-2 text-[13px] font-semibold transition-all flex items-center justify-center bg-[#1E9BD7] text-white hover:[linear-gradient(0deg, rgba(255, 255, 255, 0.1), rgba(255, 255, 255, 0.1)), #1E9BD7] no-underline flex gap-x-2  active:scale-95 scale-100 duration-75"
                          style={{
                            boxShadow:
                              "0px 1px 4px rgba(13, 34, 71, 0.17), inset 0px 0px 0px 1px #1E9BD7, inset 0px 0px 0px 2px rgba(255, 255, 255, 0.1)",
                          }}
                        >
                          <span> Continue </span>
                          <svg
                            className="w-5 h-5 group-hover:-rotate-45 transition-all duration-300"
                            viewBox="0 0 24 24"
                            fill="none"
                            xmlns="http://www.w3.org/2000/svg"
                          >
                            <path
                              d="M13.75 6.75L19.25 12L13.75 17.25"
                              stroke="#FFF"
                              strokeWidth="1.5"
                              strokeLinecap="round"
                              strokeLinejoin="round"
                            />
                            <path
                              d="M19 12H4.75"
                              stroke="#FFF"
                              strokeWidth="1.5"
                              strokeLinecap="round"
                              strokeLinejoin="round"
                            />
                          </svg>
                        </button>
                      </div>
                    </div>
                  </motion.div>
                ) : (
                  <p>Step 3</p>
                )}
              </div>
            </div>
            <div className="w-full h-[40vh] md:w-1/2 md:h-screen bg-[#F1F2F4] relative overflow-hidden">
              <svg
                id="texture"
                style={{ filter: "contrast(120%) brightness(120%)" }}
                className="fixed z-[1] w-full h-full opacity-[35%]"
              >
                <filter id="noise" data-v-1d260e0e="">
                  <feTurbulence
                    type="fractalNoise"
                    baseFrequency=".8"
                    numOctaves="4"
                    stitchTiles="stitch"
                    data-v-1d260e0e=""
                  ></feTurbulence>
                  <feColorMatrix
                    type="saturate"
                    values="0"
                    data-v-1d260e0e=""
                  ></feColorMatrix>
                </filter>
                <rect
                  width="100%"
                  height="100%"
                  filter="url(#noise)"
                  data-v-1d260e0e=""
                ></rect>
              </svg>
              <figure
                className="absolute md:top-1/2 ml-[-380px] md:ml-[0px] md:-mt-[240px] left-1/2 grid transform scale-[0.5] sm:scale-[0.6] md:scale-[130%] w-[760px] h-[540px] bg-[#f5f7f9] text-[9px] origin-[50%_15%] md:origin-[50%_25%] rounded-[15px] overflow-hidden p-2 z-20"
                style={{
                  grid: "100%/repeat(1,calc(5px * 28)) 1fr",
                  boxShadow:
                    "0 192px 136px rgba(26,43,59,.23),0 70px 50px rgba(26,43,59,.16),0 34px 24px rgba(26,43,59,.13),0 17px 12px rgba(26,43,59,.1),0 7px 5px rgba(26,43,59,.07), 0 50px 100px -20px rgb(50 50 93 / 25%), 0 30px 60px -30px rgb(0 0 0 / 30%), inset 0 -2px 6px 0 rgb(10 37 64 / 35%)",
                }}
              >
                <div className="z-20 absolute h-full w-full bg-transparent cursor-default"></div>
                <div
                  className="bg-white flex flex-col text-[#1a2b3b] p-[18px] rounded-lg relative"
                  style={{ boxShadow: "inset -1px 0 0 #fff" }}
                >
                  <ul className="mb-auto list-none">
                    <li className="list-none flex items-center">
                      <p>
                        <motion.img
                          initial={{ opacity: 0, y: 10 }}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, y: -10 }}
                          transition={{
                            duration: 0.5,
                            ease: [0.23, 1, 0.32, 1],
                          }}
                          className="block w-[200px]"
                          src="cloud-logo.png"
                          alt="cloud Brand Logo"
                        ></motion.img>
                      </p>
                    </li>
                    <li className="mt-4 list-none flex items-center rounded-[9px] text-gray-900 py-[2px]">
                      <svg
                        className="h-4 w-4 text-gray-700"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        {" "}
                        <path
                          stroke="currentColor"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1.5"
                          d="M4.75 6.75C4.75 5.64543 5.64543 4.75 6.75 4.75H17.25C18.3546 4.75 19.25 5.64543 19.25 6.75V17.25C19.25 18.3546 18.3546 19.25 17.25 19.25H6.75C5.64543 19.25 4.75 18.3546 4.75 17.25V6.75Z"
                        ></path>{" "}
                        <path
                          stroke="currentColor"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1.5"
                          d="M9.75 8.75V19"
                        ></path>{" "}
                        <path
                          stroke="currentColor"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1.5"
                          d="M5 8.25H19"
                        ></path>{" "}
                      </svg>
                      <p className="ml-[3px] mr-[6px]">Home</p>
                    </li>
                    <li className="mt-1 list-none flex items-center rounded-[9px] text-gray-900 py-[4px]">
                      <svg
                        className="w-4 h-4 text-[#1a2b3b]"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke="currentColor"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1.5"
                          d="M19.25 19.25L15.5 15.5M4.75 11C4.75 7.54822 7.54822 4.75 11 4.75C14.4518 4.75 17.25 7.54822 17.25 11C17.25 14.4518 14.4518 17.25 11 17.25C7.54822 17.25 4.75 14.4518 4.75 11Z"
                        ></path>
                      </svg>

                      {step === 1 ? (
                        <p className="ml-[3px] mr-[6px] text-blue-600">
                          Search
                        </p>
                      ) : (
                        <p className="ml-[3px] mr-[6px]">Search</p>
                      )}
                    </li>
                    <li className="mt-1 list-none flex items-center rounded-[9px] text-gray-900 py-[4px]">
                      <svg
                        className="h-4 w-4 text-gray-700"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke="currentColor"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1.5"
                          d="M4.75 6.75C4.75 5.64543 5.64543 4.75 6.75 4.75H17.25C18.3546 4.75 19.25 5.64543 19.25 6.75V17.25C19.25 18.3546 18.3546 19.25 17.25 19.25H6.75C5.64543 19.25 4.75 18.3546 4.75 17.25V6.75Z"
                        ></path>
                        <path
                          stroke="currentColor"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1.5"
                          d="M19 12L5 12"
                        ></path>
                      </svg>
                      {step === 2 ? (
                        <p className="ml-[3px] mr-[6px] text-blue-600">
                          My Questions
                        </p>
                      ) : (
                        <p className="ml-[3px] mr-[6px]">My Questions</p>
                      )}
                    </li>
                    <li className="mt-1 list-none flex items-center rounded-[9px] text-gray-900 py-[4px]">
                      <svg
                        className="h-4 w-4 text-gray-700"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke="currentColor"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1.5"
                          d="M13.1191 5.61336C13.0508 5.11856 12.6279 4.75 12.1285 4.75H11.8715C11.3721 4.75 10.9492 5.11856 10.8809 5.61336L10.7938 6.24511C10.7382 6.64815 10.4403 6.96897 10.0622 7.11922C10.006 7.14156 9.95021 7.16484 9.89497 7.18905C9.52217 7.3524 9.08438 7.3384 8.75876 7.09419L8.45119 6.86351C8.05307 6.56492 7.49597 6.60451 7.14408 6.9564L6.95641 7.14408C6.60452 7.49597 6.56492 8.05306 6.86351 8.45118L7.09419 8.75876C7.33841 9.08437 7.3524 9.52216 7.18905 9.89497C7.16484 9.95021 7.14156 10.006 7.11922 10.0622C6.96897 10.4403 6.64815 10.7382 6.24511 10.7938L5.61336 10.8809C5.11856 10.9492 4.75 11.372 4.75 11.8715V12.1285C4.75 12.6279 5.11856 13.0508 5.61336 13.1191L6.24511 13.2062C6.64815 13.2618 6.96897 13.5597 7.11922 13.9378C7.14156 13.994 7.16484 14.0498 7.18905 14.105C7.3524 14.4778 7.3384 14.9156 7.09419 15.2412L6.86351 15.5488C6.56492 15.9469 6.60451 16.504 6.9564 16.8559L7.14408 17.0436C7.49597 17.3955 8.05306 17.4351 8.45118 17.1365L8.75876 16.9058C9.08437 16.6616 9.52216 16.6476 9.89496 16.811C9.95021 16.8352 10.006 16.8584 10.0622 16.8808C10.4403 17.031 10.7382 17.3519 10.7938 17.7549L10.8809 18.3866C10.9492 18.8814 11.3721 19.25 11.8715 19.25H12.1285C12.6279 19.25 13.0508 18.8814 13.1191 18.3866L13.2062 17.7549C13.2618 17.3519 13.5597 17.031 13.9378 16.8808C13.994 16.8584 14.0498 16.8352 14.105 16.8109C14.4778 16.6476 14.9156 16.6616 15.2412 16.9058L15.5488 17.1365C15.9469 17.4351 16.504 17.3955 16.8559 17.0436L17.0436 16.8559C17.3955 16.504 17.4351 15.9469 17.1365 15.5488L16.9058 15.2412C16.6616 14.9156 16.6476 14.4778 16.811 14.105C16.8352 14.0498 16.8584 13.994 16.8808 13.9378C17.031 13.5597 17.3519 13.2618 17.7549 13.2062L18.3866 13.1191C18.8814 13.0508 19.25 12.6279 19.25 12.1285V11.8715C19.25 11.3721 18.8814 10.9492 18.3866 10.8809L17.7549 10.7938C17.3519 10.7382 17.031 10.4403 16.8808 10.0622C16.8584 10.006 16.8352 9.95021 16.8109 9.89496C16.6476 9.52216 16.6616 9.08437 16.9058 8.75875L17.1365 8.4512C17.4351 8.05308 17.3955 7.49599 17.0436 7.1441L16.8559 6.95642C16.504 6.60453 15.9469 6.56494 15.5488 6.86353L15.2412 7.09419C14.9156 7.33841 14.4778 7.3524 14.105 7.18905C14.0498 7.16484 13.994 7.14156 13.9378 7.11922C13.5597 6.96897 13.2618 6.64815 13.2062 6.24511L13.1191 5.61336Z"
                        ></path>
                        <path
                          stroke="currentColor"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1.5"
                          d="M13.25 12C13.25 12.6904 12.6904 13.25 12 13.25C11.3096 13.25 10.75 12.6904 10.75 12C10.75 11.3096 11.3096 10.75 12 10.75C12.6904 10.75 13.25 11.3096 13.25 12Z"
                        ></path>
                      </svg>
                      <p className="ml-[3px] mr-[6px]">Settings</p>
                    </li>
                  </ul>
                  <ul className="flex flex-col mb-[10px]">
                    <hr className="border-[#e8e8ed] w-full" />
                    <li className="mt-1 list-none flex items-center rounded-[9px] text-gray-900 py-[2px]">
                      <div className="h-4 w-4 bg-[#898FA9] rounded-full flex-shrink-0 text-white inline-flex items-center justify-center text-[7px] leading-[6px] pl-[0.5px]">
                        JS
                      </div>
                      <p className="ml-[4px] mr-[6px] flex-shrink-0">
                        John Smith
                      </p>
                      <div className="ml-auto">
                        <svg
                          className="h-4 w-4"
                          fill="none"
                          viewBox="0 0 24 24"
                        >
                          <path
                            fill="currentColor"
                            d="M13 12C13 12.5523 12.5523 13 12 13C11.4477 13 11 12.5523 11 12C11 11.4477 11.4477 11 12 11C12.5523 11 13 11.4477 13 12Z"
                          ></path>
                          <path
                            fill="currentColor"
                            d="M9 12C9 12.5523 8.55228 13 8 13C7.44772 13 7 12.5523 7 12C7 11.4477 7.44772 11 8 11C8.55228 11 9 11.4477 9 12Z"
                          ></path>
                          <path
                            fill="currentColor"
                            d="M17 12C17 12.5523 16.5523 13 16 13C15.4477 13 15 12.5523 15 12C15 11.4477 15.4477 11 16 11C16.5523 11 17 11.4477 17 12Z"
                          ></path>
                        </svg>
                      </div>
                    </li>
                  </ul>
                </div>
                <div className="bg-white text-[#667380] p-[18px] flex flex-col">
                  {step === 1 ? (
                    <div>
                      <motion.span
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -10 }}
                        transition={{ duration: 0.5, ease: [0.23, 1, 0.32, 1] }}
                        className="text-[#1a2b3b] text-[14px] leading-[18px] font-semibold absolute"
                      >
                        Search database
                      </motion.span>

                      <ul className="mt-[28px] flex">
                        <li className="list-none max-w-[400px]">
                          Search through all the cloud documents bank.
                        </li>
                      </ul>
                    </div>
                  ) : (
                    <div>
                      <motion.span
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -10 }}
                        transition={{ duration: 0.5, ease: [0.23, 1, 0.32, 1] }}
                        className="text-[#1a2b3b] text-[14px] leading-[18px] font-semibold absolute"
                      >
                        Ask me anything
                      </motion.span>

                      <ul className="mt-[28px] flex">
                        <li className="list-none max-w-[400px]">
                          Here you can ask our internal AI any question you
                          have. Our language model will be able to help you on
                          any document currently held in our database.
                        </li>
                      </ul>
                    </div>
                  )}
                  {step === 2 && (
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      transition={{ duration: 0.5, ease: [0.23, 1, 0.32, 1] }}
                      className="mt-[12px] flex bg-gray-100 h-[80%] rounded-lg relative ring-1 ring-gray-900/5"
                    >
                      <ChatInterface />
                    </motion.div>
                  )}
                  {step === 1 && (
                    <ul className="mt-[12px] flex items-center space-x-[2px]">
                      <svg
                        className="w-4 h-4 text-[#1a2b3b]"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke="currentColor"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1.5"
                          d="M19.25 19.25L15.5 15.5M4.75 11C4.75 7.54822 7.54822 4.75 11 4.75C14.4518 4.75 17.25 7.54822 17.25 11C17.25 14.4518 14.4518 17.25 11 17.25C7.54822 17.25 4.75 14.4518 4.75 11Z"
                        ></path>
                      </svg>

                      <p>Search</p>
                    </ul>
                  )}
                  {step === 1 && (
                    <motion.ul
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      transition={{ duration: 0.5, ease: [0.23, 1, 0.32, 1] }}
                      className="mt-3 grid grid-cols-1 xl:grid-cols-1"
                    >
                      <li className="list-none relative flex items-stretch text-left">
                        <div className="group relative w-full">
                          <div className="relative mb-2 flex h-full max-h-[500px] w-full cursor-pointer items-start justify-between rounded-lg p-2 font-medium transition duration-100">
                            <div className="absolute inset-0 rounded-lg ring-1 ring-inset ring-zinc-900/[7.5%] group-hover:ring-zinc-900/10"></div>
                            <div className="relative flex h-full flex-col overflow-hidden">
                              <TableComponent />
                            </div>
                          </div>
                        </div>
                      </li>
                    </motion.ul>
                  )}
                  {step === 1 && (
                    <div className="space-y-2 md:space-y-5 mt-auto">
                      <nav
                        className="flex items-center justify-between border-t border-gray-200 bg-white px-1 py-[2px] mb-[10px]"
                        aria-label="Pagination"
                      >
                        <div className="hidden sm:block">
                          <p className=" text-[#1a2b3b]">
                            Showing <span className="font-medium">1</span> to{" "}
                            <span className="font-medium">8</span> of{" "}
                            <span className="font-medium">500</span> results
                          </p>
                        </div>
                        <div className="flex flex-1 justify-between sm:justify-end">
                          <button className="relative inline-flex cursor-auto items-center rounded border border-gray-300 bg-white px-[4px] py-[2px]  font-medium text-[#1a2b3b] hover:bg-gray-50 disabled:opacity-50">
                            Previous
                          </button>
                          <button className="relative ml-3 inline-flex items-center rounded border border-gray-300 bg-white px-[4px] py-[2px]  font-medium text-[#1a2b3b] hover:bg-gray-50">
                            Next
                          </button>
                        </div>
                      </nav>
                    </div>
                  )}
                </div>
              </figure>
            </div>
          </div>
        )}
      </AnimatePresence>
    );
  } else {
    signIn("azure-ad");
  }
}

//@ts-nocheck
// Gotta demo this tomorrow, we'll fix it later

import "@/styles/globals.css";
import { SessionProvider } from "next-auth/react";

import { useState, useEffect } from "react";

import Head from "next/head";
import { useRouter } from "next/router";

import createCache from "@emotion/cache";

import { CacheProvider } from "@emotion/react";

import { ThemeProvider } from "@mui/material/styles";
import CssBaseline from "@mui/material/CssBaseline";

import Sidenav from "@/components/Sidenav";
import Configurator from "@/components/Configurator";

import theme from "@/assets/theme";

import themeDark from "@/assets/theme-dark";

import routes from "@/routes";

import Protected from "@/components/ProtectedPages";

import {
  MaterialUIControllerProvider,
  useMaterialUIController,
  setMiniSidenav,
  setOpenConfigurator,
} from "@/context";

import favicon from "@/assets/images/favicon.ico";
import appleIcon from "@/assets/images/apple-icon.png";
import cloudBrand from "@/assets/images/logo.png";

const clientSideEmotionCache = createCache({ key: "css", prepend: true });

function Main({ Component, pageProps }) {
  const [controller, dispatch] = useMaterialUIController();
  const {
    miniSidenav,
    direction,
    layout,
    openConfigurator,
    sidenavColor,
    darkMode,
  } = controller;
  const [onMouseEnter, setOnMouseEnter] = useState(false);
  const { pathname } = useRouter();

  const handleOnMouseEnter = () => {
    if (miniSidenav && !onMouseEnter) {
      setMiniSidenav(dispatch, false);
      setOnMouseEnter(true);
    }
  };

  const handleOnMouseLeave = () => {
    if (onMouseEnter) {
      setMiniSidenav(dispatch, true);
      setOnMouseEnter(false);
    }
  };

  const handleConfiguratorOpen = () =>
    setOpenConfigurator(dispatch, !openConfigurator);

  useEffect(() => {
    document.body.setAttribute("dir", direction);
  }, [direction]);

  useEffect(() => {
    document.documentElement.scrollTop = 0;
    document.scrollingElement.scrollTop = 0;
  }, [pathname]);

  const brandIcon = cloudBrand;

  return (
    <ThemeProvider theme={darkMode ? themeDark : theme}>
      <CssBaseline />
      <Component {...pageProps} />
      {layout === "dashboard" && pathname !== "/upload" && (
        <>
          <Sidenav
            color={sidenavColor}
            brand={brandIcon}
            brandName="cloud"
            routes={routes}
            onMouseEnter={handleOnMouseEnter}
            onMouseLeave={handleOnMouseLeave}
          />
          <Configurator />
        </>
      )}
    </ThemeProvider>
  );
}

function App({
  Component,
  pageProps: { session, ...pageProps },
  emotionCache = clientSideEmotionCache,
}: AppProps) {
  return (
    <MaterialUIControllerProvider>
      <CacheProvider value={emotionCache}>
        <Head>
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <link rel="shortcut icon" href={favicon.src} />
          <link rel="apple-touch-icon" sizes="76x76" href={appleIcon.src} />
          <title>cloud - Document Service</title>
        </Head>
        <SessionProvider session={session}>
          {Component.requireAuth ? (
            <Protected>
              <Main Component={Component} pageProps={pageProps}>
                <main className="scroll-smooth antialiased [font-feature-settings:'ss01']"></main>
              </Main>
            </Protected>
          ) : (
            <Main Component={Component} pageProps={pageProps}>
              <main className="scroll-smooth antialiased [font-feature-settings:'ss01']"></main>
            </Main>
          )}
        </SessionProvider>
      </CacheProvider>
    </MaterialUIControllerProvider>
  );
}

export default App;

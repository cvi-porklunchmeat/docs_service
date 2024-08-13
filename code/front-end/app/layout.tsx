import "../styles/globals.css";

export const metadata = {
  title: "cloud - Document Service",
  description: 'Upload and search all your documents',
}

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <link rel="shortcut icon" href="/favicon.ico" />
      </head>
      <body className="antialiased [font-feature-settings:'ss01'] ">
        {children}
      </body>
    </html>
  );
}

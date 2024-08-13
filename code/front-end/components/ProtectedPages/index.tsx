import { useSession, signIn } from "next-auth/react";
import { useRouter } from "next/router";
import { useEffect } from "react";

type Props = {
  children: React.ReactElement;
};

function Protected({ children }: Props) {
  const router = useRouter();
  const { status: sessionStatus } = useSession();
  const authorized = sessionStatus === "authenticated";
  const unAuthorized = sessionStatus === "unauthenticated";
  const loading = sessionStatus === "loading";

  useEffect(() => {
    if (loading || !router.isReady) return;

    if (unAuthorized) {
      console.log("not authorized");
      signIn("azure-ad");
    }
  }, [loading, unAuthorized, sessionStatus, router]);

  if (loading) {
    return <>Loading...</>;
  }

  return authorized ? <div>{children}</div> : <></>;
}

export default Protected;

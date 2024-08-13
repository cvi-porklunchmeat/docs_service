//@ts-nocheck
import { useSession, signIn, signOut } from "next-auth/react";

export default function testAuth() {
  const { data: session, status } = useSession(); // eslint-disable-line
  const userEmail = session?.user?.email;
  const userName = session?.user?.name;
  const userID = session?.user?.id;
  const accessToken = session?.accessToken;

  if (status === "loading") {
    return <p>Hang on there...</p>;
  }

  if (status === "authenticated") {
    return (
      <>
        <div>
          <h1>Welcome {userName}!</h1>
          <br></br>
          <p>This is what we know about you:</p>
          <ul>
            <li>Your email is: {userEmail}</li>
            <br></br>
            <li>Your id is: {userID}</li>
            <br></br>
            <li>Your JWT token is: {accessToken}</li>
          </ul>
        </div>

        <br></br>
        <button onClick={() => signOut()}>Sign out</button>
      </>
    );
  }

  return (
    <>
      <p>Not signed in.</p>
      <button onClick={() => signIn("okta")}>Sign in</button>
    </>
  );
}

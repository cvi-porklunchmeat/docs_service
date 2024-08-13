//@ts-nocheck

import NextAuth from "next-auth";
import AzureADProvider from "next-auth/providers/azure-ad";

const HALF_HOUR = 1800;

export default NextAuth({
  providers: [
    AzureADProvider({
      clientId: process.env.AZURE_AD_CLIENT_ID,
      clientSecret: process.env.AZURE_AD_CLIENT_SECRET,
      tenantId: process.env.AZURE_AD_TENANT_ID,
      authorization: { params: { scope: 'openid api://pr-72-docs_service-api/api.read' } },
    }),
  ],

  session: {
    maxAge: HALF_HOUR,
  },

  callbacks: {
    async session({ session, token }) {
      session.user.id = token.id;
      session.accessToken = token.accessToken;

      return session;
    },
    async jwt({ token, user, account }) {
      if (user) {
        token.id = user.id;
      }

      if (account) {
        token.accessToken = account.access_token;
      }

      return token;
    },
  },
});

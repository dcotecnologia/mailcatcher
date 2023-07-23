import Head from "next/head";
import initializeBasicAuth from "nextjs-basic-auth";
import MessagesTable from "../components/messages_table";

const basicAuthCheck = initializeBasicAuth({
  users: JSON.parse(process.env.MAILCATCHER_CREDENTIALS),
});

export async function getServerSideProps(ctx) {
  const { req, res } = ctx;

  await basicAuthCheck(req, res);

  return {
    props: {},
  };
}

export default function Home() {
  const API_URL = process.env.MAILCATCHER_API_URL;

  return (
    <>
      <Head>
        <link href="favicon.ico" rel="icon"></link>
      </Head>
      <header className="header" suppressHydrationWarning={true}>
        <h1>
          <a href="https://mailcatcher.me" target="_blank">
            MailCatcher
          </a>
        </h1>
        <nav className="app">
          <ul>
            <li className="search">
              <input
                type="search"
                name="search"
                placeholder="Search messages..."
                incremental="true"
              />
            </li>
            <li className="clear">
              <a href="#" title="Clear all messages">
                Clear
              </a>
            </li>
            <li className="quit">
              <a href="#" title="Quit MailCatcher">
                Quit
              </a>
            </li>
          </ul>
        </nav>
      </header>
      <MessagesTable></MessagesTable>
      <div id="resizer" suppressHydrationWarning={true}>
        <div className="ruler" />
      </div>
      <article id="message" suppressHydrationWarning={true}>
        <header>
          <dl className="metadata">
            <dt className="created_at">Received</dt>
            <dd className="created_at" />
            <dt className="from">From</dt>
            <dd className="from" />
            <dt className="to">To</dt>
            <dd className="to" />
            <dt className="subject">Subject</dt>
            <dd className="subject" />
            <dt className="attachments">Attachments</dt>
            <dd className="attachments" />
          </dl>
          <nav className="views">
            <ul>
              <li
                className="format tab html selected"
                data-message-format="html"
              >
                <a href="#">HTML</a>
              </li>
              <li className="format tab plain" data-message-format="plain">
                <a href="#">Plain Text</a>
              </li>
              <li className="format tab source" data-message-format="source">
                <a href="#">Source</a>
              </li>
              <li className="action download" data-message-format="html">
                <a href="#" className="button">
                  <span>Download</span>
                </a>
              </li>
            </ul>
          </nav>
        </header>
        <iframe className="body" />
      </article>
    </>
  );
}

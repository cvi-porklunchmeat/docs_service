import React from "react";

function ChatInterface() {
  const messages = [
    {
      sender: "user",
      content: "What is the most recent ROIC for American Express?",
    },
    {
      sender: "ai",
      content:
        "The most recent Return on Invested Capital (ROIC) for American Express is currently 4.14%",
    },
    {
      sender: "user",
      content: "What the current total debt?",
    },
    {
      sender: "ai",
      content:
        "The current total debt of American Express as of March 2023 is $43.00 billion",
    },
  ];

  return (
    <div className="chat-container bg-white rounded p-6 w-full mx-auto">
      <div className="messages overflow-auto h-64 mb-4 rounded p-3">
        {messages.map((message, index) => (
          <div
            key={index}
            className={`flex justify-${
              message.sender === "ai" ? "start" : "end"
            } mb-2`}
          >
            <div
              className={
                message.sender === "ai"
                  ? "message p-3 rounded-lg text-xs bg-gray-100 text-gray-700 max-w-1/2"
                  : "message p-3 rounded-lg text-xs bg-blue-200 text-blue-700 max-w-1/2"
              }
            >
              {message.content}
            </div>
          </div>
        ))}
      </div>
      <div className="input-area flex items-center">
        <input
          placeholder="Ask a question"
          className="w-full px-3 py-2 border rounded mr-4 text-xs"
        />
        <button className="px-4 py-2 bg-blue-500 text-white rounded text-xs">
          Send
        </button>
      </div>
    </div>
  );
}

export default ChatInterface;

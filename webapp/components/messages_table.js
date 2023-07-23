import React, { useState, useEffect } from "react";
import axios from "axios";
const MessagesTable = () => {
  const [data, setData] = useState([]);

  const API_URL = process.env.MAILCATCHER_API_URL;

  useEffect(() => {
    const fetchData = async () => {
      try {
        console.log(API_URL);
        const response = await axios.get("http://localhost:1080" + "/messages");
        setData(response.data); // Assuming the API returns an array of data
      } catch (error) {
        console.error("Error fetching data:", error);
      }
    };

    fetchData();
  }, []);

  return (
    <nav>
      <table>
        <thead>
          <tr>
            <th>From</th>
            <th>To</th>
            <th>Subject</th>
            <th>Received</th>
          </tr>
        </thead>
        <tbody>
          {data.length > 0 ? (
            <>
              {data.map((item) => (
                <tr key={item.id}>
                  <td>{item.sender}</td>
                  <td>{item.recipients}</td>
                  <td>{item.subject}</td>
                  <td>{item.created_at}</td>
                </tr>
              ))}
            </>
          ) : (
            <tr>
              <td colSpan={4}>No messages available.</td>
            </tr>
          )}
        </tbody>
      </table>
    </nav>
  );
};

export default MessagesTable;

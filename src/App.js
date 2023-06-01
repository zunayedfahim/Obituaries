import React, { createContext, useState } from "react";
import CreateObituaries from "./CreateObituaries";
import ShowObituaries from "./ShowObituaries";

export const MyContext = createContext();
const App = () => {
  const [obituaries, setObituaries] = useState([]);
  const [createObituaries, setCreateObituaries] = useState(false);
  const [showDescription, setShowDescription] = useState([]);
  return (
    <MyContext.Provider
      value={{
        createObituaries,
        setCreateObituaries,
        obituaries,
        setObituaries,
        showDescription,
        setShowDescription,
      }}
    >
      <div className={`${CreateObituaries && "overflow-x-hidden h-screen"}`}>
        {/* Navbar */}
        <div className="flex border-b-2 py-4 pr-5">
          <div className="flex-1 text-center font-bold text-lg">
            The Last Show
          </div>
          <button
            onClick={() => setCreateObituaries(true)}
            className="hover:bg-gray-600/50 bg-gray-400/50 py-1 px-3 rounded-md"
          >
            + New Obituary
          </button>
        </div>

        {/* Show Obituaries */}
        <ShowObituaries />

        {/* Create Obituaries */}
        {createObituaries && (
          <div className="absolute top-0 bottom-0 right-0 left-0">
            <button
              onClick={() => setCreateObituaries(false)}
              className="absolute right-0 top-0 mr-10 mt-5 text-3xl font-semibold"
            >
              X
            </button>
            <CreateObituaries />
          </div>
        )}
      </div>
    </MyContext.Provider>
  );
};

export default App;

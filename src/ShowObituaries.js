import React, { useContext, useEffect, useRef, useState } from "react";
import { MyContext } from "./App";
import { BsPause, BsPlay } from "react-icons/bs";
import { createRef } from "react";

const ShowObituaries = () => {
  const { obituaries, setObituaries, showDescription, setShowDescription } =
    useContext(MyContext);

  const audioRefs = useRef([]);
  const [isPlaying, setIsPlaying] = useState([]);

  useEffect(() => {
    const asyncEffect = async () => {
      let promise = null;
      promise = await fetch(
        `https://insicyycmddewtjyrx6jotzoq40pcdcz.lambda-url.ca-central-1.on.aws/`,
        {
          method: "GET",
        }
      );
      if (promise.status === 200) {
        const res = await promise.json();
        setObituaries(
          res.sort((a, b) => {
            return a.id - b.id;
          })
        );
      }
    };
    asyncEffect();
  }, []);

  const handleClick = (index) => {
    if (showDescription.includes(index)) {
      // If the index is already in the list, remove it
      setShowDescription(showDescription.filter((i) => i !== index));
    } else {
      // If the index is not in the list, add it
      setShowDescription([...showDescription, index]);
    }
  };

  const togglePlayPause = (index) => {
    const audio = audioRefs.current[index];
    if (audio.paused) {
      audio.play();
      setIsPlaying([...isPlaying, index]);
    } else {
      audio.pause();
      setIsPlaying(isPlaying.filter((i) => i !== index));
    }
  };

  return (
    <div className="flex flex-wrap justify-center mt-5 gap-24">
      {obituaries?.map(
        ({ id, name, description, imageURL, audioURL }, index) => (
          <div
            key={index}
            className={`bg-gray-100 rounded-md shadow-xl self-start lg:w-[15%] md:w-[25%] sm:w-[60%] text-center ${
              !showDescription.includes(index) && "shrink"
            } `}
          >
            <button
              onClick={() => handleClick(index)}
              key={id}
              className="w-full"
            >
              <img src={imageURL} alt={name} className="rounded-t-md w-full" />
              <h1 className="pt-3 font-semibold text-xl">{name}</h1>
            </button>

            <p className="text-center text-xs tracking-tighter leading-none italic p-2">
              {showDescription?.includes(index) && description}
            </p>
            {showDescription.includes(index) && (
              <div>
                <audio
                  ref={(element) => (audioRefs.current[index] = element)}
                  src={audioURL}
                ></audio>
                <button
                  onClick={() => togglePlayPause(index)}
                  className="bg-gray-900 text-white text-xl text-center rounded-full p-2 mb-3"
                >
                  {isPlaying.includes(index) ? <BsPause /> : <BsPlay />}
                </button>
              </div>
            )}
          </div>
        )
      )}
    </div>
  );
};

export default ShowObituaries;

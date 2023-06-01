import React, { useContext, useState } from "react";
import floral from "./floral.png";
import DateTimePicker from "react-datetime-picker";
import "react-datetime-picker/dist/DateTimePicker.css";
import "react-calendar/dist/Calendar.css";
import "react-clock/dist/Clock.css";
import { MyContext } from "./App";

const CreateObituaries = () => {
  const {
    setCreateObituaries,
    obituaries,
    showDescription,
    setShowDescription,
    setObituaries,
  } = useContext(MyContext);
  const [bornDateValue, setBornDateValue] = useState(new Date());
  const [diedDateValue, setDiedDateValue] = useState(new Date());
  const [name, setName] = useState("");
  const [imageFile, setImageFile] = useState("");
  const [disableButton, setDisableButton] = useState(false);

  // TODO: push to backend
  const createObituary = () => {
    if (!name) {
      alert("Please provide a name.");
      return;
    }
    if (!imageFile) {
      alert("Please select an image file.");
      return;
    }
    setDisableButton(true);

    const reader = new FileReader();

    reader.readAsDataURL(imageFile);
    reader.onloadend = (event) => {
      // Encode the data URL as a base64 string
      const base64String = reader.result;

      fetch(
        "https://a2b33v7q3gtmtue23ixbrn3y5m0xkqrb.lambda-url.ca-central-1.on.aws/",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            id: (obituaries.length + 1).toString(),
            name,
            born_year: bornDateValue.getFullYear().toString(),
            died_year: diedDateValue.getFullYear().toString(),
            imageData: base64String,
          }),
        }
      )
        .then(async (res) => {
          const obituary = await res.json();
          setObituaries([...obituaries, obituary]);
          setShowDescription([...showDescription, obituaries.length]);
          setDisableButton(false);
          setCreateObituaries(false);
        })
        .catch((err) => {
          console.log(err);
        });
    };
  };
  return (
    <div className="bg-gray-300/80 h-full flex flex-col justify-center items-center overflow-hidden">
      <div className="font-bold text-2xl">Create a New Obituary</div>
      <img src={floral} className="w-52" alt="floral" />

      {/* Upload Image */}
      <div className="flex gap-5 items-center mb-5">
        <p>Select an image for the deceased</p>
        <input type="file" onChange={(e) => setImageFile(e.target.files[0])} />
      </div>

      {/* Name of the deceased */}
      <input
        className="w-[30%] p-2 border border-gray-400 rounded-md"
        placeholder="Name of the Deceased"
        value={name}
        onChange={(e) => setName(e.target.value)}
      />

      {/* Date and Time */}
      <div className="flex mt-5 gap-2 items-center">
        <p>Born:</p>
        <div className="flex">
          <DateTimePicker onChange={setBornDateValue} value={bornDateValue} />
        </div>
        <p>Died:</p>
        <div>
          <DateTimePicker onChange={setDiedDateValue} value={diedDateValue} />
        </div>
      </div>

      {/* Submit Button */}
      <button
        disabled={disableButton}
        onClick={() => createObituary()}
        className="w-[30%] bg-cyan-500/80 mt-5 py-3 font-semibold rounded-md text-white hover:bg-gray-700 text-sm disabled:bg-gray-800"
      >
        Write Obituary
      </button>
    </div>
  );
};

export default CreateObituaries;

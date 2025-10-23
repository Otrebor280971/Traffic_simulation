import { useState, useRef } from 'react';

export default function App() {
  let [location, setLocation] = useState("");
  let [lights, setLights] = useState([]);
  let [simSpeed, setSimSpeed] = useState(10);
  const running = useRef(null);

  let setup = () => {
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({  })
    }).then(resp => resp.json())
    .then(data => {
      setLocation(data["Location"]);
      setLights(data["lights"]);
    });
  }

  const handleStart = () => {
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
      .then(res => res.json())
      .then(data => {
        setLights(data["lights"]);
      });
    }, 1000 / simSpeed);
  };

  const handleStop = () => {
    clearInterval(running.current);
  }

  return (
    <div>
      <div>
        <button onClick={setup}>Setup</button>
        <button onClick={handleStart}>Start</button>
        <button onClick={handleStop}>Stop</button>
      </div>
      <svg width="800" height="500" xmlns="http://www.w3.org/2000/svg" style={{backgroundColor:"white"}}>
        <rect x={0} y={200} width={800} height={100} fill="darkgray" />
        <rect x={350} y={0} width={100} height={500} fill="darkgray" />
        {lights.map(light => {
          const col = light.color === 0 ? 'green' : light.color === 1 ? 'yellow' : 'red';
          const cx = light.pos[0] * 80;
          const cy = light.pos[1] * 50;
          return <circle key={light.id} cx={cx} cy={cy} r={10} fill={col} stroke="black" />;
        })}
      </svg>
    </div>
  );
}

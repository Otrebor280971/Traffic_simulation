import { useState, useRef } from 'react';

export default function App() {
  let [location, setLocation] = useState("");
  let [lights, setLights] = useState([]);
  let [cars, setCars] = useState([]);
  let [simSpeed, setSimSpeed] = useState(10);
  let [avgSpeed, setAvgSpeed] = useState(0.0);
  let [numCars, setNumCars] = useState(3);
  const running = useRef(null);
  const [isRunning, setIsRunning] = useState(false);

  let setup = () => {
    handleStop();
    setLocation("");
    setLights([]);
    setCars([]);
    setAvgSpeed(0.0);
    setIsRunning(false);

    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({  n_cars: parseInt(numCars)})
    }).then(resp => resp.json())
    .then(data => {
      setLocation(data["Location"]);
      setLights(data["lights"] || []);
      setCars(data["cars"] || []);
    });
  }

  const handleStart = () => {
    if (isRunning || !location) return;
    setIsRunning(true);

    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
      .then(res => res.json())
      .then(data => {
        setLights(data["lights"] || []);
        setCars(data["cars"] || []);
        setAvgSpeed(data["avg_speed"] || 0.0);
      })
      .catch(err => {
        console.error("Error fetching simulation step: ", err);
        handleStop();
      });
    }, 1000 / simSpeed);
  };

  const handleStop = () => {
    clearInterval(running.current);
    running.current = null;
    setIsRunning(false);
  }

  const scaleX = (x) => x * 80;
  const scaleY = (y) => y * 50;

  return (
    <div>
      <div>
        <button onClick={setup}>Setup</button>
        <button onClick={handleStart}>Start</button>
        <button onClick={handleStop}>Stop</button>
        <div className="flex-grow">
          <label htmlFor="num-cars" className="block text-sm font-medium text-gray-700">Autos por Calle:</label>
          <select
            id="num-cars"
            value={numCars}
            onChange={(e) => setNumCars(e.target.value)}
            disabled={isRunning}
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
          >
            <option value={3}>3 Autos</option>
            <option value={5}>5 Autos</option>
            <option value={7}>7 Autos</option>
          </select>
        </div>
      </div>
      <svg width="800" height="500" xmlns="http://www.w3.org/2000/svg" style={{backgroundColor:"white"}}>
        <rect x={0} y={250} width={800} height={100} fill="darkgray" />
        <rect x={430} y={0} width={100} height={500} fill="darkgray" />
        {lights.map(light => {
          const col = light.color === 0 ? 'green' : light.color === 1 ? 'yellow' : 'red';
          const cx = light.pos[0] * 80;
          const cy = light.pos[1] * 50;
          return <circle key={light.id} cx={cx} cy={cy} r={10} fill={col} stroke="black" />;
        })}
        {cars.map(car => {
            const isHorizontal = car.direction === "Horizontal";
            const imageSize = 32;
            
            const cx = scaleX(car.pos[0]);
            const cy = scaleY(car.pos[1]);

            const x_img = cx - (imageSize / 2);
            const y_img = cy - (imageSize / 2);
            
            const transformStr = isHorizontal ? "" : `rotate(90, ${cx}, ${cy})`;

            return (
              <image
                key={car.id}
                href="./racing-car.png"
                x={x_img}
                y={y_img}
                width={imageSize}
                height={imageSize}
                transform={transformStr}
              />
            );
          })}
      </svg>
      <div className="bg-white p-4 rounded-lg shadow-md mt-4 w-full max-w-4xl">
        <p className="text-sm text-gray-700 mt-2">
          Velocidad Promedio: <span className="font-bold text-blue-600">{avgSpeed.toFixed(3)}</span>
        </p>
        <p className="text-sm text-gray-500">
          Autos Totales: <span className="font-bold">{cars.length}</span>
        </p>
      </div>

    </div>
  );
}

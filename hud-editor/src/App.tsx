import Toolbar from './components/Toolbar';
import ElementLibrary from './components/ElementLibrary';
import Canvas from './components/Canvas';
import PropertiesPanel from './components/PropertiesPanel';
import ChatPanel from './components/ChatPanel';

export default function App() {
  return (
    <div className="app">
      <Toolbar />
      <div className="app-body">
        <ElementLibrary />
        <Canvas />
        <PropertiesPanel />
      </div>
      <ChatPanel />
    </div>
  );
}

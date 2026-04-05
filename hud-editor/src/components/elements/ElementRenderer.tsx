import { HudElement } from '../../types';
import LabelElement from './LabelElement';
import ButtonElement from './ButtonElement';
import SliderElement from './SliderElement';
import IconElement from './IconElement';
import ListElement from './ListElement';
import CardhandElement from './CardhandElement';
import ContainerElement from './ContainerElement';
import SpacerElement from './SpacerElement';

export default function ElementRenderer({ element }: { element: HudElement }) {
  switch (element.type) {
    case 'label': return <LabelElement element={element} />;
    case 'button': return <ButtonElement element={element} />;
    case 'slider': return <SliderElement element={element} />;
    case 'icon': return <IconElement element={element} />;
    case 'list': return <ListElement element={element} />;
    case 'cardhand': return <CardhandElement />;
    case 'container': return <ContainerElement element={element} />;
    case 'spacer': return <SpacerElement />;
    default: return <div style={{ color: '#666', fontSize: 10 }}>{element.type}</div>;
  }
}

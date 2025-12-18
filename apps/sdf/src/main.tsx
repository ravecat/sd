import { StrictMode } from 'react';
import * as ReactDOM from 'react-dom/client';
import NiceModal from '@ebay/nice-modal-react';
import App from './app/app';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <StrictMode>
    <NiceModal.Provider>
      <App />
    </NiceModal.Provider>
  </StrictMode>
);

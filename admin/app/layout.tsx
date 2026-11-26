import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'YUKU Admin',
  description: 'YUKU marketplace operations dashboard',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="id"><body>{children}</body></html>;
}

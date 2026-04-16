/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export default function App() {
  return (
    <div className="min-h-screen bg-[#0a0c0f] text-[#cfd8dc] font-mono p-8 flex flex-col items-center justify-center">
      <div className="max-w-3xl w-full border border-[#1e2d40] bg-[#0f1318] p-8 rounded-lg shadow-2xl">
        <header className="mb-8 border-b border-[#1e2d40] pb-6">
          <h1 className="text-3xl font-bold text-white mb-2">CPU Emulator & Debugger</h1>
          <p className="text-[#90a4ae] text-sm uppercase tracking-widest">End Semester Project - Computer Architecture</p>
        </header>

        <section className="space-y-6">
          <div>
            <h2 className="text-[#00e676] text-lg font-bold mb-4">Project Overview</h2>
            <p className="leading-relaxed text-[#90a4ae]">
              A custom 32-bit RISC-style processor simulation implemented in MASM assembly. 
              Featuring a full Fetch-Decode-Execute cycle, instruction tracing, and complex bit-manipulation instructions.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-4 py-6 border-y border-[#1e2d40]">
            <div className="space-y-2">
              <h3 className="text-[#00bcd4] font-bold">Custom ISA</h3>
              <ul className="text-xs space-y-1 text-[#546e7a]">
                <li>• ROTBLEND (Rotate + XOR)</li>
                <li>• SCRAMBLE (Bit Permutation)</li>
                <li>• BITFUSE (Interleaving)</li>
                <li>• SNAPSHOT (State Backup)</li>
              </ul>
            </div>
            <div className="space-y-2">
              <h3 className="text-[#ffb300] font-bold">Architecture</h3>
              <ul className="text-xs space-y-1 text-[#546e7a]">
                <li>• 8 x 32-bit Registers (R0-R7)</li>
                <li>• 256B Emulated Memory</li>
                <li>• 3 Status Flags (Z, N, C)</li>
                <li>• Fixed 4-byte Encoding</li>
              </ul>
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-4 pt-4">
            <a 
              href="/gui/index.html" 
              className="flex-1 text-center bg-[#00e676]/10 border border-[#00e676] text-[#00e676] py-3 rounded font-bold hover:bg-[#00e676]/20 transition-all cursor-pointer"
            >
              Open Web Visualizer
            </a>
            <div className="flex-1 text-center bg-[#1a2230] border border-[#2a3f58] text-[#cfd8dc] py-3 rounded text-sm px-4">
              Run <code className="text-[#ffb300]">build_and_run.bat</code> for MASM Version
            </div>
          </div>
        </section>

        <footer className="mt-12 pt-6 border-t border-[#1e2d40] flex justify-between text-[10px] text-[#546e7a] uppercase tracking-tighter">
          <span>Saad · Tayyab · Shaheer · Maheen</span>
          <span>© 2026 CS Architecture Lab</span>
        </footer>
      </div>
    </div>
  );
}

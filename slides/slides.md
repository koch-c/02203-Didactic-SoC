---
theme: default
title: Sobel accelerator — design update
info: |
  Design evolution, memory architecture, implementation status and next steps.
fonts:
  sans: Arial
  mono: monospace
  provider: none
colorSchema: light
transition: none
drawings:
  persist: false
defaults:
  layout: default
---

# Problems with original designs

<div class="design-steps">
  <div>
    <span class="step">01</span>
    <h3>Column-wise loading</h3>
    <p>Reconsidered when we needed to assemble four output pixels into one complete 32-bit write.</p>
  </div>
  <div>
    <span class="step">02</span>
    <h3>Large register file</h3>
    <p>About 600 words and nine read ports. A straightforward read-mux estimate alone used <strong>≈88% of available LUTs</strong>.</p>
  </div>
  <div>
    <span class="step">03</span>
    <h3>Develop a working version</h3>
    <p>Keep it simple and maybe slighlty less efficient. Then we can consider redesigning it</p>
  </div>
</div>


---

# Compute 1 row at a time and keep a rolling window of 7 words in memory

<img class="memory-diagram" src="./memory.png" alt="Rolling seven-word memory: compute the first two pixels, load the next column, then compute the last two pixels." />

---

# Selecting the pixel neighbourhoods

<img class="loader-diagram" src="./loader.png" alt="Loader sketch showing pixel selection for the first and last halves of an output word, using circular indices modulo seven." />

---

# Status and Implementation Details

<div class="columns">
  <div>
    <h3>Implemented</h3>
    <ul>
      <li>Memory</li>
      <li>Loader</li>
      <li>Parts of the FSM</li>
    </ul>
    <div class="callout">Today's goal: a running accelerator.</div>
  </div>
  <div>
    <h3>Processing schedule</h3>
    <ul>
      <li>Two pixels computed in parallel</li>
      <li>Each input word read three times</li>
      <li>One word read per cycle</li>
    </ul>
    <div class="throughput">≈1,315 <span>frames/s</span></div>
    <div class="calculation">25,344 words/frame = 288 × 352 / 4<br>100,000,000 / (25,344 × 3) ≈ 1,315</div>
  </div>
</div>

<div class="footnote">Optimistic estimate at clock speed of 100MHz</div>

---

# Finish, integrate, then optimize

<div class="next-steps">
  <div><span class="step">01</span><div><h3>Integrate with the SoC</h3><p>Connect and verify the complete accelerator flow.</p></div></div>
  <div><span class="step">02</span><div><h3>Improve buffering</h3><p>Reuse data so each input word is read fewer times.</p></div></div>
  <div><span class="step">03</span><div><h3>Add resource sharing</h3><p>Reduce duplicated hardware where the schedule allows.</p></div></div>
  <div><span class="step">04</span><div><h3>Support border pixels</h3><p>Extend processing to the image boundaries.</p></div></div>
</div>

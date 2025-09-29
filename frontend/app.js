const API_BASE = "";

const faqListEl = document.getElementById("faq-list");
const messagesEl = document.getElementById("messages");
const form = document.getElementById("chat-form");
const input = document.getElementById("msg-input");

function addMessage(text, who = "bot", meta = "") {
  const div = document.createElement("div");
  div.className = "msg " + (who === "user" ? "user" : "bot");
  div.innerHTML = `<div>${text}</div><div style="margin-top:6px;font-size:11px;color:#b5c6bf">${meta}</div>`;
  messagesEl.appendChild(div);
  messagesEl.scrollTop = messagesEl.scrollHeight;
}

// ✅ FAQs ثابتة بدل ما تيجي من السيرفر
async function fetchFaqs() {
  const staticFaqs = [
   "When does registration for the new semester start?",
    "How can I register for a course?",
    "What is the deadline for course add/drop?",
    "How can I pay my tuition fees?",
    "How is GPA calculated?",
    "What scholarships are available?",
  ];

  faqListEl.innerHTML = "";
  staticFaqs.forEach((q) => {
    const li = document.createElement("li");
    li.textContent = q;
    li.onclick = () => {
      input.value = q;
      input.focus();
    };
    faqListEl.appendChild(li);
  });
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const text = input.value.trim();
  if (!text) return;
  addMessage(text, "user");
  input.value = "";
  addMessage("Thinking...", "bot", "");
  const pending = messagesEl.lastChild;

  try {
    const res = await fetch(API_BASE + "/api/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ msg: text })
    });
    const data = await res.json();
    if (pending) pending.remove();

    if (data.error) {
      addMessage("Error: " + data.error, "bot");
    } else if (data.suggestions) {
      // 👇 حالة الـ confidence قليلة → إعرض clarifications
      addMessage(data.answer, "bot");
      if (data.clarification) {
        addMessage(data.clarification, "bot");
      }

      // عرض الاقتراحات كأزرار
      const sugDiv = document.createElement("div");
      sugDiv.className = "suggestions";
      data.suggestions.forEach((sug) => {
        const btn = document.createElement("button");
        btn.textContent = sug;
        btn.onclick = (ev) => {
          ev.preventDefault();
          input.value = sug;
          form.dispatchEvent(new Event("submit"));
        };
        sugDiv.appendChild(btn);
      });
      messagesEl.appendChild(sugDiv);
      messagesEl.scrollTop = messagesEl.scrollHeight;
    } else {
      const meta = data.score ? `Confidence: ${(data.score * 100).toFixed(0)}%` : "";
      addMessage(data.answer, "bot", meta);
      if (data.source_question) {
        addMessage(`Source: "${data.source_question}"`, "bot", "");
      }
    }
  } catch (err) {
    console.error(err);
    if (pending) pending.remove();
    addMessage("Failed to connect to the server. Please make sure the backend is running.", "bot");
  }
});

fetchFaqs();

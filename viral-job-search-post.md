# Viral Post: Claude Routines for Job Search Automation

---

## LinkedIn Post (Long-Form Viral Version)

---

I automated my entire job search using Claude.

No more copy-pasting. No more blank-stare cover letters. No more forgetting to follow up.

Here's the exact Claude routine stack I built — steal it:

---

**1. The Job Radar (runs every morning)**

A Claude hook that scrapes your target companies' career pages + LinkedIn + GitHub job boards, filters by your criteria (role, stack, location, seniority), and drops a ranked digest into your Slack/email.

You wake up to a curated list. Not 300 irrelevant postings.

```
Prompt: "Here are today's job listings from [sources]. 
I'm a senior ML engineer with 4 years exp in PyTorch, 
computer vision, and edge deployment. Rank the top 5 
by fit and explain why in 1 sentence each."
```

---

**2. The Resume Sniper (per application, 3 mins)**

Feed Claude the JD + your master resume. It outputs a tailored resume that mirrors the exact language of the job posting — hitting ATS keywords without keyword stuffing.

```
Prompt: "Here's the job description: [JD]
Here's my master resume: [RESUME]
Rewrite the bullet points to align with this specific role.
Keep it truthful. Surface the most relevant projects first."
```

Most people apply with the same resume everywhere. This is the cheat code.

---

**3. The Cold Outreach Machine (5 mins per message)**

Stop sending "Hi, I'm interested in opportunities at your company."

Give Claude: the person's LinkedIn, their recent posts, your background, the role you want.

Get back: a hyper-personalized 4-line message that references something specific they said or built. Response rates jump 3-4x.

```
Prompt: "Write a cold LinkedIn message to [Name], 
a senior engineer at [Company]. They recently posted about [topic]. 
I'm an AI researcher interested in their [team/project]. 
Keep it under 5 sentences. No fluff. End with a specific question."
```

---

**4. The Interview Prep Loop (the night before)**

Feed Claude the JD + company's recent blog posts + the interviewer's LinkedIn.

It generates:
- 10 likely technical questions for this specific role
- 5 behavioral questions based on their team values
- Your talking points mapped to their stack
- Questions YOU should ask them (that make you look sharp)

```
Prompt: "I'm interviewing at [Company] for [Role] tomorrow. 
Here's the JD, their engineering blog post, and my background. 
Generate a personalized prep sheet: likely questions, 
my best talking points, and 3 questions I should ask."
```

---

**5. The Follow-Up Guardian (automated)**

A Claude Code hook that triggers 48 hours after any application or interview email. It drafts a context-aware follow-up — referencing what was discussed, not a generic "just checking in."

The hiring manager remembers you. Most candidates disappear.

---

**6. The Offer Negotiator (when the time comes)**

Paste the offer letter. Claude gives you:
- Market comp benchmarks for the role/location
- The 3 levers to negotiate (base, equity, signing bonus)
- A word-for-word negotiation script that doesn't burn the relationship

```
Prompt: "Here's the offer: [OFFER]. 
I have [X] years of experience and competing offers at [Y range]. 
Write a negotiation email that is confident but collaborative. 
Specific numbers. No vague language."
```

---

**The full stack, summarized:**

| Routine | Trigger | Time saved |
|---|---|---|
| Job Radar | Daily, 7am | 1-2 hrs/day |
| Resume Sniper | Per application | 45 mins/app |
| Cold Outreach | Before every DM | 30 mins/msg |
| Interview Prep | Night before | 2-3 hrs/interview |
| Follow-Up Guardian | 48hr post-contact | Never forget again |
| Offer Negotiator | Offer received | Thousands in comp |

---

Job searching in 2025 without AI is like navigating without GPS.

You'll get there. But slower, more stressed, and with worse outcomes.

The candidates getting hired at top companies aren't working harder. They're working with better tools.

Build the stack. Run the routines. Close the loop.

---

Drop a "🔥" in the comments if you want me to share the actual Claude Code hook configs.

---

#JobSearch #AITools #CareerAdvice #ClaudeAI #Productivity #Machinelearning #TechCareers #JobHunting

---

## Twitter/X Thread Version

---

**Tweet 1 (Hook):**
I automated my job search with Claude routines.
6 workflows. 0 cold sweats. Multiple offers.

Here's the exact stack (thread 🧵):

---

**Tweet 2:**
1/ The Job Radar

Every morning, Claude scans job boards, filters by YOUR criteria, ranks the top 5 by fit with a 1-line reason each.

You wake up to signal, not noise.

---

**Tweet 3:**
2/ The Resume Sniper

Feed Claude the JD + your master resume.
It rewrites your bullets to mirror the job's exact language.

ATS-optimized. Truthful. Specific to the role.

Stop sending the same resume everywhere.

---

**Tweet 4:**
3/ Cold Outreach Machine

Input: person's LinkedIn + recent posts + what you want
Output: 5-sentence personalized message that gets replies

Response rate went from ~5% to ~20% for me.

---

**Tweet 5:**
4/ Interview Prep Loop

Night before: feed Claude the JD + company blog + interviewer's profile.

Get back:
• Likely questions for THIS role
• Your best talking points
• Questions that make you look sharp

Walk in prepared. Every time.

---

**Tweet 6:**
5/ Follow-Up Guardian

Claude Code hook fires 48hrs after any application/interview.

Drafts a context-aware follow-up. Not "just checking in" — something specific.

Hiring managers remember you. Most candidates disappear.

---

**Tweet 7:**
6/ Offer Negotiator

Paste the offer → get market benchmarks, negotiation levers, and a word-for-word email.

Confident. Collaborative. Specific numbers.

I left $0 on the table.

---

**Tweet 8 (CTA):**
Job searching without AI in 2025 is like navigating without GPS.

You'll get there. Just slower and more stressed.

RT if this helped. Reply with which routine you're building first 👇

---

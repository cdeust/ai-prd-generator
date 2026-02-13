# Legal & Integrity

Complete transparency on intellectual property ownership, development timeline, and cryptographic proof of origin.
This project was developed independently as freelance work, with full traceability via blockchain timestamp.

---

## Intellectual Property Ownership

The AI-PRD Generator project is the sole property of **Clément Deust**, developed as an independent freelance initiative.
Development was conducted exclusively outside of any employment obligations, using personal equipment and resources.

### Legal Context

- Freelance activity established and disclosed prior to current employment
- Development conducted entirely outside working hours (48% of commits between 18h-06h, including 13 commits between 00h-06h)
- No use of proprietary code, data, or infrastructure from any employer
- Complete commit history with timestamp analysis available for verification

---

## Development Timeline

| Date | Milestone |
|------|-----------|
| **September 2025** | Initial proof-of-concept ([ai-prd-generator](https://github.com/cdeust/ai-prd-generator)). First commit: September 11, 2025, 23:16 UTC. |
| **October 2025** | Structured development begins ([ai-prd](https://github.com/cdeust/ai-prd)). Clean architecture implementation, SOLID principles, Zero Tolerance rules. First commit: October 5, 2025, 17:36 CET. |
| **October - December 2025** | Core feature development: RAG engine (hybrid vector/text search), Vision engine (mockup interpretation), Chain of Verification (multi-LLM validation). |
| **January 2026** | Packaging as Anthropic Skill ([ai-prd-generator](https://github.com/cdeust/ai-prd-generator)). Internal testing with positive feedback. Landing page and pilot program launch. |
| **January 28, 2026** | Cryptographic timestamp proof anchored on Bitcoin blockchain (Block 934075). Archive SHA-256 hash and OpenTimestamps proof created for legal traceability. |

---

## Cryptographic Proof of Origin

To establish irrefutable proof of intellectual property ownership and development timeline,
a comprehensive timestamp analysis has been anchored on the Bitcoin blockchain using OpenTimestamps.

### Blockchain Timestamp Details

| Field | Value |
|-------|-------|
| **Archive Date** | 2026-01-28 10:00:39 CET |
| **Bitcoin Block** | 934075 |
| **Block Timestamp** | 2026-01-28 11:04:01 CET (1769594641 Unix) |
| **Transaction ID** | `937f1e849b25d9ed69d5ccd417ae08ed286452231090918fa996447149d8c29f` |
| **Archive SHA-256** | `34524454db245e62b1ce80ecd98eee63f7e777e7eaa6ecc9f1a95c4360493d7f` |

### Archive Contents

The timestamped archive contains:

- Complete commit history analysis (102 commits across ai-prd and ai-prd-generator repositories)
- Timestamp distribution showing 48% of commits between 18h-06h (evening/night)
- 13 commits between 00h-06h (night hours, impossible during standard work hours)
- Detailed analysis demonstrating work conducted exclusively outside employment hours
- Export of all commits with full timestamps and metadata

### Verification

The timestamp proof can be independently verified using OpenTimestamps:

```bash
# 1. Install OpenTimestamps
pip3 install opentimestamps-client

# 2. Verify Bitcoin blockchain proof
ots verify [archive.ots]

# 3. Verify archive integrity
shasum -a 256 [archive.tar.gz]

# 4. Compare hash with certified value
# Expected: 34524454db245e62b1ce80ecd98eee63f7e777e7eaa6ecc9f1a95c4360493d7f
```

---

## License

This software is provided under a **Development License** for evaluation and testing purposes only.

See [LICENSE](LICENSE) for full terms.

### Commercial Licensing

While the core technology is available for evaluation, commercial deployment requires a separate licensing agreement providing:

- Dedicated technical support and integration assistance
- Custom template development for specific organizational processes
- Formal evaluation framework and reporting
- Priority feature development aligned with organization needs
- Access to commercial secured distribution
- Optional exclusivity agreements for specific sectors

---

## Transparency Commitment

All development activity is publicly traceable on GitHub. The blockchain timestamp provides cryptographic proof
that cannot be forged or backdated. This level of transparency ensures:

- Clear intellectual property ownership
- Verifiable development timeline
- Proof of independent development outside employment obligations
- Full traceability for legal purposes if required

---

## Contact

For questions regarding intellectual property, licensing, or verification of timestamp proof:

- **Email**: clement.deust@proton.me
- **GitHub**: [@cdeust](https://github.com/cdeust)
- **LinkedIn**: [Clément Deust](https://www.linkedin.com/in/clementdeust)

---

*Blockchain timestamp proof: Bitcoin Block 934075 | SHA-256: 34524454db245e62b1ce80ecd98eee63f7e777e7eaa6ecc9f1a95c4360493d7f*

import 'package:flutter/material.dart';

/// Starboard (jobb) oldal — hajós (navigációs-fény) konvenció szerint zöld.
const Color starboardColor = Color(0xFF34C759);

/// Port (bal) oldal — hajós (navigációs-fény) konvenció szerint piros.
const Color portColor = Color(0xFFE5484D);

/// Folyamatban lévő verseny státusz-színe — a téma-seed teal-családból.
/// Külön token a starboard/port mellett, NEM a `ConfidenceColors.high`,
/// hogy a predikció-konfidencia szemantikájával ne keveredjen (ADR 0033).
const Color inProgressColor = Color(0xFF1E9FB5);

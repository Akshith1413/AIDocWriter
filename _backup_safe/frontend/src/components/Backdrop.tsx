import { motion } from "framer-motion";

export function Backdrop() {
  return (
    <div className="backdrop" aria-hidden="true">
      <motion.div
        className="aura aura-one"
        animate={{ x: [0, 90, -20, 0], y: [0, 40, 110, 0], scale: [1, 1.18, 0.95, 1] }}
        transition={{ duration: 19, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="aura aura-two"
        animate={{ x: [0, -70, 30, 0], y: [0, 80, -25, 0], scale: [1.1, 0.94, 1.16, 1.1] }}
        transition={{ duration: 23, repeat: Infinity, ease: "easeInOut" }}
      />
      <div className="mesh" />
      <div className="grain" />
    </div>
  );
}


import React from "react";
import { BrowserRouter as Router, Route, Switch, Link } from "react-router-dom";
import { hot } from "react-hot-loader";

import About from "./About";
import Home from "./Home";
import NotFound from "./NotFound";
import "./App.css";

const App = () => (
  <Router>
    <React.Fragment>
      <nav>
        <Link to="/">Home</Link> | <Link to="/about">About</Link> |{" "}
        <Link to="/404">404</Link> | <a href="https://github.com/rxseven/playground-docker" rel="noopener noreferrer" target="_blank">View on GitHub</a>
      </nav>
      <main>
        <Switch>
          <Route component={Home} exact path="/" />
          <Route component={About} path="/about" />
          <Route component={NotFound} />
        </Switch>
      </main>
      <footer><code>v0.0.34</code></footer>
    </React.Fragment>
  </Router>
);

export default hot(module)(App);

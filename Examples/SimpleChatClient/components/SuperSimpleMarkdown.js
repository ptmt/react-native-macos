
import React from 'react-native-desktop';
import SimpleMarkdown from 'simple-markdown';

const {
  View,
  Text,
  Image
} = React;

export default class Markdown extends React.Component {

  componentWillMount() {

    const rules = generateRules(styles);
    const mixedRules = { ...rules, ...SimpleMarkdown.defaultRules};
    const parser = SimpleMarkdown.parserFor(mixedRules);
    this.parse = source => {
      return parser(source + '\n\n', {inline: false});
    };
    this.renderer = SimpleMarkdown.reactFor(SimpleMarkdown.ruleOutput(rules, 'react'));
  }

  render() {
    const tree = this.parse(this.props.children);
    return (
      <View style={styles.view}>
        {this.renderer(tree)}
      </View>
    );
  }
}

const generateRules = styles => {
  return {
    autolink: {
      react: function(node, output, state): ReactElement {
        state.withinText = true;
        return React.createElement(Text, {
          key: state.key,
          style: styles.link,
          onPress: () => console.log('pressed')
        }, output(node.content, state));
      }
    },
    newline: {
      react: function() { return null; }
    },
    codeBlock: {
      react: function(node, output, state) {
        state.withinText = true;
        return React.createElement(Text, {
          key: state.key,
          style: [styles.text, styles.codeBlock]
        }, null);
      }
    },
    del: {
      react: function(node, output, state) {
        state.withinText = true;
        return React.createElement(Text, {
          key: state.key,
          style: styles.del
        }, output(node.content, state));
      }
    },
    em: {
      react: function(node, output, state) {
        state.withinText = true;
        return React.createElement(Text, {
          key: state.key,
          style: styles.em
        }, output(node.content, state));
      }
    },
    image: {
      react: function(node, output, state) {
        return React.createElement(Image, {
          key: state.key,
          source: { uri: node.target },
          style: styles.image
        });
      }
    },
    inlineCode: {
      react: function(node, output, state) {
        state.withinText = true;
        return React.createElement(View, {
          key: state.key,
          style: [styles.code],
          children: React.createElement(Text, {
            style: [styles.text, styles.inlineCode],
            children: node.content
          })
        });
      }
    },
    link: {
      react: function(node, output, state) {
        state.withinText = true;
        return React.createElement(Text, {
          key: state.key,
          style: [styles.text, styles.link],
          children: node.content[0].content
        });
      }
    },
    list: {
      react: function(node, output, state) {

        var items = node.items.map(function(item, i) {
          var bullet;
          if (node.ordered) {
            bullet = React.createElement(Text, { style: styles.listItemNumber  }, (i + 1) + '. ');
          }
          else {
            bullet = React.createElement(Text, { style: styles.listItemBullet }, '\u2022 ');
          }
          return React.createElement(View, {
            key: i,
            style: styles.listItem
          }, [bullet, output(item, state)]);
        });

        return React.createElement(View, { key: state.key, style: styles.list }, items);
      }
    },
    paragraph: {
      react: function(node, output, state) {
        return React.createElement(View, {
          key: state.key,
          style: styles.paragraph
        }, output(node.content, state));
      }
    },
    strong: {
      react: function(node, output, state) {
        state.withinText = true;
        return React.createElement(Text, {
          key: state.key,
          style: styles.strong
        }, output(node.content, state));
      }
    },
    text: {
      react: function(node, output, state) {

        var textStyles = [styles.text];
        if (typeof node.content.split !== 'function') {
          return React.createElement(Text, {
            style: textStyles
          }, node.content);
        }
        //Breaking words up in order to allow for text reflowing in flexbox
        var words = node.content.split(' ');
        words = words.map((word, i) => {
          var elements = [];
          if (i != words.length - 1) {
            word = word + ' ';
          }
          if (!state.withinText) {
            textStyles.push(styles.plainText);
          }
          return React.createElement(Text, {
            style: textStyles
          }, word);
        });
        return words;
      }
    },
    heading: {
      react: function(node, output, state) {
        var textStyles = [styles.text];
        if (typeof node.content.split !== 'function') {
          return React.createElement(Text, {
            style: textStyles
          }, node.content);
        }

        //Breaking words up in order to allow for text reflowing in flexbox
        var words = node.content.split(' ');
        words = words.map((word, i) => {
          var elements = [];
          if (i != words.length - 1) {
            word = word + ' ';
          }
          if (!state.withinText) {
            textStyles.push(styles.plainText);
          }
          return React.createElement(Text, {
            style: textStyles
          }, word);
        });
        return words;
      }
    },
    url: {
      react: function(node, output, state) {
        state.withinText = true;
        return React.createElement(Text, {
          key: state.key,
          style: styles.url,
          onPress: console.log//_.noop
        }, output(node.content, state));
      }
    }
  }
};

const styles = {
  view: {
    marginLeft: 5,
    flex: 1,
    // alignItems: 'flex-start',
    // justifyContent: 'flex-start',
    flexWrap: 'wrap',
  },
  codeBlock: {
    fontFamily: 'Monaco',
    //fontWeight: '500'
  },
  del: {
    containerBackgroundColor: '#222222'
  },
  em: {
    fontStyle: 'italic'
  },
  code: {
    backgroundColor: '#eeeeee',
    borderColor: '#dddddd',
    borderRadius: 3,
    borderWidth: 1,
  },
  inlineCode: {
    fontFamily: 'Monaco',
    //fontWeight: 'bold'
  },
  list: {

  },
  listItem: {
    flexDirection: 'row'
  },
  listItemBullet: {
    fontSize: 20,
    lineHeight: 20
  },
  listItemNumber: {
    fontWeight: 'bold'
  },
  paragraph: {
    // marginTop: 10,
    // marginBottom: 10,
    //flex: 1,
    flexWrap: 'wrap',
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'flex-start'
  },
  strong: {
    fontWeight: 'bold'
  },
  text: {
    fontSize: 12,
    color: '#222222'
  },
  link: {
    color: '#2929f0'
  },
  url: {
    color: 'blue'
  }
};
